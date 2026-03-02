const MODAL_ORIGIN = "http://localhost:3000";


function updateExtensionIcon(enabled) {
  const path = enabled
    ? {
        16: "icons/icon16.png",
        48: "icons/icon48.png",
        128: "icons/icon128.png",
      }
    : {
        16: "icons/icon16-gray.png",
        48: "icons/icon48-gray.png",
        128: "icons/icon128-gray.png",
      };

  chrome.action.setIcon({ path });
}

// Run when extension is installed or updated
chrome.runtime.onInstalled.addListener(() => {
  chrome.storage.local.get(["enabled"], (result) => {
    const isEnabled = result.enabled !== false;
    updateExtensionIcon(isEnabled);
  });
});

// Run when browser starts
chrome.runtime.onStartup.addListener(() => {
  chrome.storage.local.get(["enabled"], (result) => {
    const isEnabled = result.enabled !== false;
    updateExtensionIcon(isEnabled);
  });
});

// React instantly to toggle changes
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.enabled) {
    updateExtensionIcon(changes.enabled.newValue);
  }
});



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

  const tabId = sender.tab?.id;
  if (!tabId) {
    console.warn("[BG] No tabId");
    return false;
  }

  if (request.action === "requestOpenModal") {
    handleOpenModal(tabId, request.quote);
    sendResponse({ success: true });
    return true;
  }

  if (request.action === "tokenFromConnect") {
    const token = request.token;

    if (token && token.length > 20) {
      chrome.storage.local.set({ skookooToken: token }, () => {
        if (chrome.runtime.lastError) {
          console.error("[BG] SAVE FAILED:", chrome.runtime.lastError.message);
          return;
        }

        chrome.storage.local.get("skookooToken", (result) => {
          const readToken = result.skookooToken;

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

  try {
    const result = await chrome.storage.local.get("skookooToken");
    let token = result?.skookooToken;

    // Safety: clear bad tokens
    if (token && (token.length < 50 || !token.includes('exp'))) {
      console.log("[BG] Bad token detected – clearing");
      await chrome.storage.local.remove("skookooToken");
      token = null;
    }

    if (token && token.length > 20) {
      chrome.tabs.sendMessage(tabId, {
        action: "openSkookooModal",
        quote: quote,
        token: token
      });
    } else {
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