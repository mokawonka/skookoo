document.getElementById('save').onclick = async () => {
  const token = document.getElementById('token').value.trim();
  const status = document.getElementById('status');
  if (!token) {
    status.textContent = 'Enter a token first.';
    return;
  }
  await chrome.storage.local.set({ skookooToken: token });
  status.textContent = 'Token saved! You can close this.';
  status.style.color = 'green';
};

chrome.storage.local.get(['skookooToken'], (r) => {
  if (r.skookooToken) {
    document.getElementById('token').value = r.skookooToken;
    document.getElementById('status').textContent = 'Token already saved.';
  }
});
