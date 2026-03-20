document.addEventListener("turbo:load", function() {

let currentShareUrl    = '';
let currentShareTitle  = '';
let currentShareAuthor = '';

function openShareSheet(btn) {
  currentShareUrl    = btn.dataset.shareUrl;
  currentShareTitle  = btn.dataset.shareTitle;
  currentShareAuthor = btn.dataset.shareAuthor;

  document.getElementById('share-book-title').textContent  = currentShareTitle;
  document.getElementById('share-book-author').textContent = currentShareAuthor;
  document.getElementById('share-url-input').value         = currentShareUrl;

  resetCopyButton();

  const nativeBtn = document.getElementById('native-share-btn');
  nativeBtn.style.display = navigator.share ? 'flex' : 'none';

  document.getElementById('share-overlay').classList.add('active');
  document.getElementById('share-sheet').classList.add('open');
  document.body.style.overflow = 'hidden';
}

function closeShareSheet() {
  document.getElementById('share-overlay').classList.remove('active');
  document.getElementById('share-sheet').classList.remove('open');
  document.body.style.overflow = '';
}

function copyShareLink() {
  navigator.clipboard.writeText(currentShareUrl).then(() => {
    const icon    = document.getElementById('copy-icon');
    const label   = document.getElementById('copy-label');
    const copyBtn = document.querySelector('.share-url-copy-btn');

    icon.classList.add('copied');
    // swap the img for a checkmark SVG temporarily
    icon.innerHTML = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none"
      stroke="#0f6e56" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
      <polyline points="20 6 9 17 4 12"/></svg>`;
    label.textContent = 'Copied!';
    if (copyBtn) copyBtn.textContent = 'Copied!';

    setTimeout(resetCopyButton, 2200);
  });
}

function resetCopyButton() {
  const icon    = document.getElementById('copy-icon');
  const label   = document.getElementById('copy-label');
  const copyBtn = document.querySelector('.share-url-copy-btn');

  if (!icon) return;

  icon.classList.remove('copied');
  // restore the original img tag — adjust the path to match your asset pipeline
  icon.innerHTML = `<img src="/assets/copy.png" width="24" height="24">`;
  label.textContent = 'Copy';
  if (copyBtn) copyBtn.textContent = 'Copy';
}

function whatsappShare() {
  const text = encodeURIComponent(`${currentShareTitle} by ${currentShareAuthor}: ${currentShareUrl}`);
  window.open(`https://wa.me/?text=${text}`, '_blank');
}

function xShare() {
  const text = encodeURIComponent(`${currentShareTitle} by ${currentShareAuthor}: ${currentShareUrl}`);
  window.open(`https://x.com/intent/post?text=${text}`, '_blank');
}

function redditShare() {
  const title = encodeURIComponent(`${currentShareTitle} by ${currentShareAuthor}`);
  const url   = encodeURIComponent(currentShareUrl);
  window.open(`https://www.reddit.com/submit?title=${title}&url=${url}`, '_blank');
}

function linkedinShare() {
  const url = encodeURIComponent(currentShareUrl);
  window.open(`https://www.linkedin.com/shareArticle?mini=true&url=${url}`, '_blank');
}

function emailShare() {
  const subject = encodeURIComponent(`Check out: ${currentShareTitle}`);
  const body    = encodeURIComponent(`I thought you'd enjoy this:\n\n${currentShareTitle} by ${currentShareAuthor}\n\n${currentShareUrl}`);
  window.location.href = `mailto:?subject=${subject}&body=${body}`;
}

function nativeShare() {
  if (navigator.share) {
    navigator.share({
      title: currentShareTitle,
      text:  `${currentShareTitle} by ${currentShareAuthor}`,
      url:   currentShareUrl
    });
  }
}

window.openShareSheet  = openShareSheet;
window.closeShareSheet = closeShareSheet;
window.copyShareLink   = copyShareLink;
window.emailShare      = emailShare;
window.nativeShare     = nativeShare;
window.whatsappShare  = whatsappShare;
window.xShare         = xShare;
window.redditShare    = redditShare;
window.linkedinShare  = linkedinShare;

// Escape key listener — registered once on load
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') closeShareSheet();
});

});