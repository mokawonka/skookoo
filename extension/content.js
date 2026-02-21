(() => {
  const MODAL_ORIGIN = "http://localhost:3000";
  const MODAL_PATH = "/extension_modal";

  let floatButton = null;
  let overlay = null;

  function removeFloatButton() {
    if (floatButton) {
      floatButton.remove();
      floatButton = null;
    }
  }

  function handleMouseUp() {
    const selection = window.getSelection();
    if (!selection || selection.isCollapsed) {
      removeFloatButton();
      return;
    }

    const text = selection.toString().trim();
    if (!text) {
      removeFloatButton();
      return;
    }

    let range;
    try {
      range = selection.getRangeAt(0);
    } catch (e) {
      removeFloatButton();
      return;
    }

    const rect = range.getBoundingClientRect();
    const top = rect.top + window.scrollY - 32;
    const left = rect.left + window.scrollX;

    if (!floatButton) {
      floatButton = document.createElement("button");
      floatButton.textContent = "React with Skookoo";
      floatButton.className = "skookoo-highlight-button";
      floatButton.addEventListener("click", () => {
        openSkookooModal(text);
        removeFloatButton();
      });
      document.body.appendChild(floatButton);
    }

    floatButton.style.top = `${Math.max(top, 0)}px`;
    floatButton.style.left = `${left}px`;
  }

  function openSkookooModal(quote) {
    if (overlay) return;

    const pageUrl = window.location.href;
    const pageTitle = document.title;

    chrome.storage.local.get(["skookooToken"], (r) => {
      const token = (r && r.skookooToken) ? r.skookooToken : "";
      const tokenParam = token ? `&token=${encodeURIComponent(token)}` : "";

      overlay = document.createElement("div");
      overlay.id = "skookoo-overlay";
      overlay.innerHTML = `
        <div class="skookoo-overlay-backdrop"></div>
        <div class="skookoo-iframe-wrapper">
          <iframe
            class="skookoo-iframe"
            src="${MODAL_ORIGIN}${MODAL_PATH}?quote=${encodeURIComponent(quote)}&url=${encodeURIComponent(pageUrl)}&title=${encodeURIComponent(pageTitle)}${tokenParam}"
            allow="clipboard-write"
          ></iframe>
        </div>
      `;

      document.body.appendChild(overlay);

      overlay.addEventListener("click", (e) => {
        if (e.target.classList.contains("skookoo-overlay-backdrop")) {
          closeSkookooModal();
        }
      });

      document.addEventListener("keydown", escListener);
    });
  }

  function escListener(e) {
    if (e.key === "Escape") {
      closeSkookooModal();
    }
  }

  function closeSkookooModal() {
    if (!overlay) return;
    overlay.remove();
    overlay = null;
    document.removeEventListener("keydown", escListener);
  }

  document.addEventListener("mouseup", handleMouseUp);
})();
