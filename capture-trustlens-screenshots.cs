using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

internal static class TrustLensScreenshotCapture
{
    [DllImport("dwmapi.dll")]
    private static extern int DwmFlush();

    private static object GetField(object target, string name)
    {
        FieldInfo field = target.GetType().GetField(
            name,
            BindingFlags.Instance | BindingFlags.NonPublic);
        if (field == null)
        {
            throw new InvalidOperationException("Campo de captura não encontrado: " + name);
        }
        return field.GetValue(target);
    }

    private static void Capture(TrustLensApp app, string outputPath)
    {
        app.Opacity = 1;
        app.Activate();
        app.BringToFront();
        app.Refresh();
        Application.DoEvents();
        DwmFlush();
        Thread.Sleep(1200);
        Application.DoEvents();
        DwmFlush();
        Rectangle bounds = app.Bounds;
        using (Bitmap image = new Bitmap(bounds.Width, bounds.Height))
        using (Graphics graphics = Graphics.FromImage(image))
        {
            graphics.CopyFromScreen(bounds.Location, Point.Empty, bounds.Size);
            image.Save(outputPath, ImageFormat.Png);
        }
    }

    private static void Navigate(TrustLensApp app, int index)
    {
        SidebarControl sidebar = (SidebarControl)GetField(app, "sidebar");
        Button[] buttons = (Button[])GetField(sidebar, "navigationButtons");
        buttons[index].PerformClick();
        Application.DoEvents();
    }

    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length != 1)
        {
            Console.Error.WriteLine("Indique a pasta de saída das capturas.");
            return 2;
        }

        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Directory.CreateDirectory(args[0]);

        ConstructorInfo constructor = typeof(TrustLensApp).GetConstructor(
            BindingFlags.Instance | BindingFlags.NonPublic,
            null,
            Type.EmptyTypes,
            null);
        if (constructor == null)
        {
            throw new InvalidOperationException("Construtor da TrustLens não encontrado.");
        }

        TrustLensApp app = (TrustLensApp)constructor.Invoke(new object[0]);
        try
        {
            app.TopMost = true;
            app.Show();
            app.Activate();
            app.BringToFront();
            Capture(app, Path.Combine(args[0], "app-analyzer-ready.png"));

            TextBox messageInput = (TextBox)GetField(app, "messageInput");
            Button checkButton = (Button)GetField(app, "checkButton");
            messageInput.Text = "A sua conta bancária será bloqueada. Envie o código de acesso para evitar a suspensão.";
            checkButton.PerformClick();
            while (!checkButton.Enabled)
            {
                Application.DoEvents();
                Thread.Sleep(40);
            }
            Capture(app, Path.Combine(args[0], "app-analyzer-high-risk.png"));

            messageInput.Text = "A consulta está confirmada para terça-feira às 10:30. Pode alterar a marcação através da aplicação oficial.";
            checkButton.PerformClick();
            while (!checkButton.Enabled)
            {
                Application.DoEvents();
                Thread.Sleep(40);
            }
            Capture(app, Path.Combine(args[0], "app-analyzer-low-risk.png"));

            int[] sections = { 1, 2, 3, 4, 5 };
            string[] names =
            {
                "app-link-checker.png",
                "app-learning.png",
                "app-safety-guide.png",
                "app-settings.png",
                "app-about.png"
            };
            for (int index = 0; index < sections.Length; index++)
            {
                Navigate(app, sections[index]);
                Capture(app, Path.Combine(args[0], names[index]));
            }
        }
        finally
        {
            app.Close();
            app.Dispose();
            Application.DoEvents();
        }

        Console.WriteLine("Captured eight genuine TrustLens application screens.");
        return 0;
    }
}
