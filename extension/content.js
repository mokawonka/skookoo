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

  // ✅ Check extension context
  if (!chrome?.runtime?.id) {
    console.warn("[CONTENT] Extension context missing. Reloading page.");
    location.reload();
    return;
  }

  try {
    chrome.runtime.sendMessage(
      {
        action: "requestOpenModal",
        quote: quote,
        origin: window.location.origin
      },
      (response) => {
        if (chrome.runtime.lastError) {
          console.warn(
            "[CONTENT] Send failed:",
            chrome.runtime.lastError.message
          );

          // If extension was reloaded, refresh content script
          if (chrome.runtime.lastError.message.includes("context invalidated")) {
            location.reload();
          }

          return;
        }

        console.log("[CONTENT] Message sent OK");
      }
    );
  } catch (err) {
    console.error("[CONTENT] Messaging crashed:", err);

    // Force recovery
    location.reload();
  }
}

function generateUUID() {
  if (crypto.randomUUID) {
    return crypto.randomUUID();
  }
  // Fallback (very rare in 2025+ Chrome)
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

function openSkookooModal(quote, token) {
  // Parse the current URL
  const urlObj = new URL(window.location.href);

  // Remove the sk_highlight parameter if it exists
  urlObj.searchParams.delete("sk_highlight");

  // Encode the cleaned URL
  const pageUrl = encodeURIComponent(urlObj.toString());
  const pageTitle = encodeURIComponent(document.title || "Web Page");
  const quoteEnc = encodeURIComponent(quote);
  const docid = generateUUID();

  const existing = document.getElementById("skookoo-iframe");
  if (existing) existing.remove();

  const iframe = document.createElement("iframe");
  iframe.id = "skookoo-iframe";
  iframe.className = "skookoo-iframe";
  iframe.src = `${MODAL_ORIGIN}${MODAL_PATH}?quote=${quoteEnc}&url=${pageUrl}&title=${pageTitle}&docid=${docid}&token=${encodeURIComponent(token)}`;

  iframe.style.position = "fixed";
  iframe.style.top = "50%";
  iframe.style.left = "50%";
  iframe.style.transform = "translate(-50%, -50%)";
  iframe.style.width = "90%";
  iframe.style.maxWidth = "600px";
  iframe.style.height = "80vh";
  iframe.style.border = "3px solid #0951a9";
  iframe.style.borderRadius = "21px";
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
  try {
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

  } catch (err) {
    console.error("[CONTENT] Listener crashed:", err);
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

window.addEventListener("message", (event) => {
  if (event.data?.action === "closeSkookooModal") {
    const iframe = document.getElementById("skookoo-iframe");
    if (iframe) iframe.remove();
  }
});

document.addEventListener("mouseup", handleMouseUp);

document.addEventListener("mousedown", (e) => {
  if (floatButton && !floatButton.contains(e.target)) {
    removeFloatButton();
  }
});


(function() {
  // Run immediately when script injects
  processHighlightParams();

  // Re-run on navigation (history.pushState, back/forward)
  let lastUrl = location.href;
  new MutationObserver(() => {
    const url = location.href;
    if (url !== lastUrl) {
      lastUrl = url;
      processHighlightParams();
    }
  }).observe(document, { subtree: true, childList: true });

  // Also listen for popstate (back/forward)
  window.addEventListener('popstate', processHighlightParams);

  function processHighlightParams() {
    const params = new URLSearchParams(window.location.search);
    const quoteToHighlight = params.get("sk_highlight");

    if (quoteToHighlight) {
      const targetQuote = decodeURIComponent(quoteToHighlight).trim();
      console.log("[CONTENT] Processing highlight quote:", targetQuote.substring(0, 50) + "...");

      // Delay slightly to ensure DOM is ready (safe)
      setTimeout(() => {
        highlightAndScrollToQuote(targetQuote);
      }, 500); // 500ms delay – adjust if needed (100-1000ms)
    }
  }


function highlightAndScrollToQuote(searchText) {
  if (!searchText || searchText.length < 5) return;

  const normalize = str =>
    str.replace(/\s+/g, ' ').trim().toLowerCase();

  const target = normalize(searchText);

  const walker = document.createTreeWalker(
    document.body,
    NodeFilter.SHOW_TEXT,
    {
      acceptNode(node) {
        if (!node.nodeValue) return NodeFilter.FILTER_REJECT;

        const parentTag = node.parentNode?.tagName;
        if (["SCRIPT", "STYLE", "NOSCRIPT"].includes(parentTag)) {
          return NodeFilter.FILTER_REJECT;
        }

        return NodeFilter.FILTER_ACCEPT;
      }
    }
  );

  let fullText = "";
  const nodes = [];
  let node;

  while ((node = walker.nextNode())) {
    const raw = node.nodeValue;
    const normalized = normalize(raw);

    nodes.push({
      node,
      start: fullText.length,
      rawLength: raw.length,
      normalizedLength: normalized.length,
      rawText: raw
    });

    fullText += normalized + " "; // ✅ critical fix
  }

  const matchStart = fullText.indexOf(target);
  if (matchStart === -1) {
    console.warn("[CONTENT] No match found");
    return;
  }

  const matchEnd = matchStart + target.length;

  let startObj = null;
  let endObj = null;

  for (const obj of nodes) {
    const nodeStart = obj.start;
    const nodeEnd = obj.start + obj.normalizedLength;

    if (!startObj && matchStart >= nodeStart && matchStart < nodeEnd) {
      startObj = obj;
    }

    if (!endObj && matchEnd > nodeStart && matchEnd <= nodeEnd) {
      endObj = obj;
      break;
    }
  }

  if (!startObj || !endObj) {
    console.warn("[CONTENT] Could not map nodes");
    return;
  }

  const range = document.createRange();

  const startOffset = matchStart - startObj.start;
  const endOffset = matchEnd - endObj.start;

  range.setStart(startObj.node, startOffset);
  range.setEnd(endObj.node, endOffset);

  const mark = document.createElement("mark");
  mark.className = "skookoo-highlight";

  // ✅ safer than surroundContents for large ranges
  const extracted = range.extractContents();
  mark.appendChild(extracted);
  range.insertNode(mark);

  mark.scrollIntoView({
    behavior: "smooth",
    block: "center"
  });

  mark.classList.add("skookoo-pulse");
  setTimeout(() => mark.classList.remove("skookoo-pulse"), 8000);
}

})();