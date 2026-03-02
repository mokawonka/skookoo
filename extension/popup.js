document.addEventListener("DOMContentLoaded", () => {
  const toggle = document.getElementById("toggleSwitch");
  const statusText = document.getElementById("statusText");
  const statusDot = document.getElementById("statusDot");

  // Load saved state
  chrome.storage.local.get(["enabled"], (result) => {
    const isEnabled = result.enabled !== false;
    toggle.checked = isEnabled;
    updateUI(isEnabled);
  });

  // Toggle change
  toggle.addEventListener("change", () => {
    const isEnabled = toggle.checked;

    // Save state only
    chrome.storage.local.set({ enabled: isEnabled });

    updateUI(isEnabled);
  });

  function updateUI(enabled) {
    statusText.textContent = enabled ? "Enabled" : "Disabled";
    statusDot.style.background = enabled ? "#22c55e" : "#ef4444";
  }
});