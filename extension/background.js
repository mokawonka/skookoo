const MODAL_ORIGIN = "http://localhost:3000";

// Context menu – idempotent
if (chrome.contextMenus) {
  chrome.contextMenus.create({
    id: "reactWithSkookoo",
    title: "React with Skookoo",
    contexts: ["selection"]
  }, () => {
    if (chrome.runtime.lastError) {
      // silent on duplicate
    } else {
      console.log("[BG] Context menu created");
    }
  });
} else {
  console.warn("[BG] contextMenus API not available");
}

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId !== "reactWithSkookoo" || !tab?.id) return;
  handleOpenModal(tab.id, info.selectionText);
});

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log("[BG] Received:", request.action, request);

  const tabId = sender.tab?.id;
  if (!tabId) {
    console.warn("[BG] No tabId");
    return false;
  }

  if (request.action === "requestOpenModal") {
    handleOpenModal(tabId, request.quote);
    return true;
  }

  if (request.action === "tokenFromConnect") {
    const token = request.token;
    console.log("[BG] TokenFromConnect received – length:", token?.length || 0);

    if (token && token.length > 20) {
      chrome.storage.local.set({ skookooToken: token }, () => {
        if (chrome.runtime.lastError) {
          console.error("[BG] SAVE FAILED:", chrome.runtime.lastError.message);
          return;
        }
        console.log("[BG] Token saved OK");

        chrome.storage.local.get("skookooToken", (result) => {
          const readToken = result.skookooToken;
          console.log("[BG] Read-back:", readToken ? `success (length ${readToken.length})` : "FAILED");

          if (readToken) {
            chrome.tabs.sendMessage(tabId, {
              action: "openSkookooModal",
              quote: request.quote || "",
              token: readToken
            });
          } else {
            console.error("[BG] Read-back failed");
          }
        });
      });
    } else {
      console.warn("[BG] Invalid token received – ignoring");
    }
    return true;
  }

  return false;
});

async function handleOpenModal(tabId, quote) {
  console.log("[BG] handleOpenModal – quote:", quote?.substring(0, 50) || "no quote", "tab:", tabId);

  try {
    const result = await chrome.storage.local.get("skookooToken");
    let token = result?.skookooToken;

    // Safety: clear bad tokens
    if (token && (token.length < 50 || !token.includes('exp'))) {
      console.log("[BG] Bad token detected – clearing");
      await chrome.storage.local.remove("skookooToken");
      token = null;
    }

    console.log("[BG] Token lookup:", token ? `present (len ${token.length})` : "MISSING");

    if (token && token.length > 20) {
      console.log("[BG] Using stored token");
      chrome.tabs.sendMessage(tabId, {
        action: "openSkookooModal",
        quote: quote,
        token: token
      });
    } else {
      console.log("[BG] No valid token – opening connect");
      const tab = await chrome.tabs.get(tabId);
      const pageOrigin = new URL(tab.url).origin;
      const connectUrl = `${MODAL_ORIGIN}/extension_connect?origin=${encodeURIComponent(pageOrigin)}`;

      chrome.tabs.sendMessage(tabId, {
        action: "openConnectWindow",
        connectUrl: connectUrl,
        quote: quote
      });
    }
  } catch (err) {
    console.error("[BG] handleOpenModal crashed:", err);
  }
}