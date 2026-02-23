// content.js

const MODAL_ORIGIN = "http://localhost:3000";
const MODAL_PATH = "/extension_modal";

let floatButton = null;
let currentQuote = null; // remember quote during reconnect

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
      requestOpenModal(text);
      removeFloatButton();
    });

    document.body.appendChild(floatButton);
  }

  floatButton.style.position = "absolute";
  floatButton.style.top = `${Math.max(top, 0)}px`;
  floatButton.style.left = `${left}px`;
  floatButton.style.zIndex = "10000";
}

function requestOpenModal(quote) {
  currentQuote = quote;
  chrome.runtime.sendMessage({
    action: "requestOpenModal",
    quote: quote,
    origin: window.location.origin
  }).catch(err => {
    console.error("Messaging error:", err);
  });
}

function openSkookooModal(quote, token) {
  const pageUrl = encodeURIComponent(window.location.href);
  const pageTitle = encodeURIComponent(document.title || "Web Page");
  const quoteEnc = encodeURIComponent(quote);

  const existing = document.getElementById("skookoo-iframe");
  if (existing) existing.remove();

  const iframe = document.createElement("iframe");
  iframe.id = "skookoo-iframe";
  iframe.className = "skookoo-iframe";
  iframe.src = `${MODAL_ORIGIN}${MODAL_PATH}?quote=${quoteEnc}&url=${pageUrl}&title=${pageTitle}&token=${encodeURIComponent(token)}`;

  iframe.style.position = "fixed";
  iframe.style.top = "50%";
  iframe.style.left = "50%";
  iframe.style.transform = "translate(-50%, -50%)";
  iframe.style.width = "90%";
  iframe.style.maxWidth = "600px";
  iframe.style.height = "80vh";
  iframe.style.border = "2px solid #0951a9";
  iframe.style.boxShadow = "0 15px 40px rgba(0,0,0,0.5)";
  iframe.style.zIndex = "2147483647";
  iframe.style.background = "#fff";
  iframe.allow = "fullscreen";

  iframe.onload = () => console.log("[CONTENT] Iframe loaded");
  iframe.onerror = () => console.error("[CONTENT] Iframe failed to load");

  document.body.appendChild(iframe);

  // Close on outside click
  const closeOnOutsideClick = (e) => {
    if (iframe.contains(e.target)) return;
    iframe.remove();
    console.log("[CONTENT] Modal closed by outside click");
    document.removeEventListener("click", closeOnOutsideClick);
  };

  setTimeout(() => {
    document.addEventListener("click", closeOnOutsideClick);
  }, 100);
}

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log("[CONTENT] Received from background:", request.action, request);

  if (request.action === "openSkookooModal") {
    console.log("[CONTENT] Opening modal with token length:", request.token?.length || 0);
    if (request.quote || request.selectedText) {
      openSkookooModal(request.quote || request.selectedText, request.token);
    }
    return false;
  }

  if (request.action === "openConnectWindow") {
    console.log("[CONTENT] Opening connect popup:", request.connectUrl);

    const connectWin = window.open(
      request.connectUrl,
      "skookoo_connect",
      "width=600,height=700,menubar=no,toolbar=no,location=no,status=no"
    );

    if (!connectWin || connectWin.closed) {
      console.error("[CONTENT] Popup blocked");
      return false;
    }

    const messageHandler = (event) => {
      console.log("[CONTENT] postMessage received:", event.origin, event.data);

      // Accept localhost variations
      if (!event.origin.includes("localhost:3000") && !event.origin.includes("127.0.0.1:3000")) {
        console.warn("[CONTENT] Origin mismatch:", event.origin);
        return;
      }

      if (event.data?.type === "SKOOKOO_TOKEN" && event.data.token) {
        console.log("[CONTENT] VALID TOKEN RECEIVED – forwarding", event.data.token.length);

        chrome.runtime.sendMessage({
          action: "tokenFromConnect",
          token: event.data.token,
          quote: request.quote || currentQuote || ""
        }, (res) => {
          if (chrome.runtime.lastError) {
            console.error("[CONTENT] Forward failed:", chrome.runtime.lastError.message);
          } else {
            console.log("[CONTENT] Token forwarded");
          }
        });

        connectWin.close();
        window.removeEventListener("message", messageHandler);
      }
    };

    window.addEventListener("message", messageHandler);

    const checkClosed = setInterval(() => {
      if (connectWin.closed) {
        console.log("[CONTENT] Connect window closed");
        window.removeEventListener("message", messageHandler);
        clearInterval(checkClosed);
      }
    }, 500);

    return false;
  }

  return false;
});

// Handle reconnect from iframe
window.addEventListener("message", (event) => {
  const iframe = document.getElementById("skookoo-iframe");
  if (!iframe || event.source !== iframe.contentWindow) return;

  if (event.data?.action === "skookooReconnect" || event.data?.action === "skookooTokenExpired") {
    console.log("[CONTENT] Reconnect requested from iframe");

    // Remove iframe
    if (iframe) {
      iframe.style.transition = "opacity 0.3s ease";
      iframe.style.opacity = "0";
      setTimeout(() => iframe.remove(), 300);
    }

    // Clear bad token
    chrome.storage.local.remove("skookooToken", () => {
      console.log("[CONTENT] Cleared bad token");

      // Force connect popup (token missing → connect flow)
      chrome.runtime.sendMessage({
        action: "requestOpenModal",
        quote: currentQuote || "reconnect"
      });
    });
  }
});

document.addEventListener("mouseup", handleMouseUp);

document.addEventListener("mousedown", (e) => {
  if (floatButton && !floatButton.contains(e.target)) {
    removeFloatButton();
  }
});