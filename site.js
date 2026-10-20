"use strict";

const menuToggle = document.querySelector(".menu-toggle");
const mainNav = document.querySelector("#main-nav");

if (menuToggle && mainNav) {
  menuToggle.addEventListener("click", () => {
    const isOpen = menuToggle.getAttribute("aria-expanded") === "true";
    menuToggle.setAttribute("aria-expanded", String(!isOpen));
    mainNav.classList.toggle("is-open", !isOpen);
  });

  mainNav.addEventListener("click", (event) => {
    if (event.target instanceof HTMLAnchorElement) {
      menuToggle.setAttribute("aria-expanded", "false");
      mainNav.classList.remove("is-open");
    }
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && menuToggle.getAttribute("aria-expanded") === "true") {
      menuToggle.setAttribute("aria-expanded", "false");
      mainNav.classList.remove("is-open");
      menuToggle.focus();
    }
  });
}

const galleryTrack = document.querySelector("#gallery-track");
const galleryCards = Array.from(document.querySelectorAll(".gallery-card"));
const galleryButtons = Array.from(document.querySelectorAll(".gallery-open"));
const lightbox = document.querySelector(".lightbox");
const lightboxImage = document.querySelector(".lightbox-image");
const lightboxCaption = document.querySelector(".lightbox-caption");
let activeImageIndex = 0;
let lastGalleryButton = null;

function showGalleryImage(index) {
  activeImageIndex = (index + galleryCards.length) % galleryCards.length;
  const card = galleryCards[activeImageIndex];
  const image = card.querySelector("img");
  const title = card.querySelector("figcaption strong").textContent;
  const description = card.querySelector("figcaption span").textContent;

  lightboxImage.src = image.src;
  lightboxImage.alt = image.alt;
  lightboxCaption.textContent = `${title} — ${description}`;
}

galleryButtons.forEach((button, index) => {
  button.addEventListener("click", () => {
    lastGalleryButton = button;
    showGalleryImage(index);
    lightbox.showModal();
  });
});

document.querySelector(".lightbox-previous").addEventListener("click", () => {
  showGalleryImage(activeImageIndex - 1);
});

document.querySelector(".lightbox-next").addEventListener("click", () => {
  showGalleryImage(activeImageIndex + 1);
});

document.querySelector(".lightbox-close").addEventListener("click", () => {
  lightbox.close();
});

lightbox.addEventListener("close", () => {
  if (lastGalleryButton) {
    lastGalleryButton.focus();
  }
});

lightbox.addEventListener("click", (event) => {
  if (event.target === lightbox) {
    lightbox.close();
  }
});

document.addEventListener("keydown", (event) => {
  if (!lightbox.open) {
    return;
  }

  if (event.key === "Escape") {
    event.preventDefault();
    lightbox.close();
  } else if (event.key === "ArrowLeft") {
    event.preventDefault();
    showGalleryImage(activeImageIndex - 1);
  } else if (event.key === "ArrowRight") {
    event.preventDefault();
    showGalleryImage(activeImageIndex + 1);
  }
});

if (galleryTrack) {
  document.querySelector(".gallery-scroll-back").addEventListener("click", () => {
    galleryTrack.scrollBy({ left: -galleryTrack.clientWidth * 0.8, behavior: "smooth" });
  });

  document.querySelector(".gallery-scroll-forward").addEventListener("click", () => {
    galleryTrack.scrollBy({ left: galleryTrack.clientWidth * 0.8, behavior: "smooth" });
  });
}

const copyHashButton = document.querySelector(".copy-hash");
const installerHash = document.querySelector("#installer-hash");
const copyStatus = document.querySelector("#copy-status");

copyHashButton.addEventListener("click", async () => {
  const hash = installerHash.textContent.trim();

  try {
    await navigator.clipboard.writeText(hash);
    copyStatus.textContent = "Hash SHA-256 copiado.";
  } catch (error) {
    const selection = window.getSelection();
    const range = document.createRange();
    range.selectNodeContents(installerHash);
    selection.removeAllRanges();
    selection.addRange(range);
    const copied = document.execCommand("copy");
    selection.removeAllRanges();
    copyStatus.textContent = copied
      ? "Hash SHA-256 copiado."
      : "Não foi possível copiar automaticamente. Selecione e copie o hash.";
  }
});
