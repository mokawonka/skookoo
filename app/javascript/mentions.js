document.addEventListener("turbo:load", () => {

  const cache = new Map()
  let abortController = null
  let debounceTimer = null
  const DEBOUNCE_MS = 250

  // ─── Attach listeners ───────────────────────────────────────────
  function attachToEditors() {
    const editors = [
      ...document.querySelectorAll("textarea"),
      ...document.querySelectorAll("trix-editor")
    ]
    editors.forEach(editor => {
      if (editor.dataset.mentionsAttached) return
      editor.dataset.mentionsAttached = "true"
      editor.addEventListener("input",   (e) => handleInput(e, editor))
      editor.addEventListener("keydown", (e) => handleKeydown(e, editor))
    })
  }

  // ─── Extract @query from caret position ────────────────────────
  function extractQuery(editor) {
    let text, caretPos

    if (editor.tagName.toLowerCase() === "trix-editor") {
      text = editor.innerText
      caretPos = text.length   // trix always appends
    } else {
      caretPos = editor.selectionStart
      text = editor.value.substring(0, caretPos)
    }

    const match = text.match(/@([\w\s]{2,30})$/)
    return match ? match[1].trim().toLowerCase() : null
  }

  // ─── Input handler ──────────────────────────────────────────────
  function handleInput(e, editor) {
    clearTimeout(debounceTimer)
    const query = extractQuery(editor)
    if (!query || query.length < 2) { closeDropdown(); return }
    debounceTimer = setTimeout(() => fetchMentions(query, editor), DEBOUNCE_MS)
  }

  // ─── Fetch ──────────────────────────────────────────────────────
  async function fetchMentions(query, editor) {
    if (cache.has(query)) { renderDropdown(cache.get(query), editor); return }

    if (abortController) abortController.abort()
    abortController = new AbortController()

    try {
      const res = await fetch(`/users/mention_search?q=${encodeURIComponent(query)}`, {
        signal: abortController.signal,
        headers: { "Accept": "application/json" }
      })
      if (!res.ok) return
      const users = await res.json()

      cache.set(query, users)
      if (cache.size > 50) cache.delete(cache.keys().next().value)

      renderDropdown(users, editor)
    } catch (err) {
      if (err.name !== "AbortError") console.error("Mention fetch error:", err)
    }
  }

  // ─── Render rich dropdown ───────────────────────────────────────
  let activeIndex = -1

  function renderDropdown(users, editor) {
    const dropdown = getOrCreateDropdown()
    dropdown.innerHTML = ""
    activeIndex = -1

    if (!users.length) { closeDropdown(); return }

    users.forEach((user, i) => {
      const div = document.createElement("div")
      div.className = "mention-item"
      div.dataset.index = i
      div.innerHTML = `
        <img class="mention-avatar" src="${escapeHtml(user.avatar_url)}" alt="">
        <div class="mention-info">
            <span class="mention-name">${escapeHtml(user.name)}</span>
            <span class="mention-username">@${escapeHtml(user.username)}</span>
        </div>
        ${user.is_following
          ? `<span class="mention-badge mention-following">Following</span>`
          : ``
        }
      `
      div.addEventListener("mousedown", (e) => { e.preventDefault(); insertMention(editor, user.username) })
      div.addEventListener("mouseenter", () => setActive(i))
      dropdown.appendChild(div)
    })

    positionAtCaret(dropdown, editor)
    dropdown.style.display = "block"
  }

  function positionAtCaret(dropdown, editor) {
  if (editor.tagName.toLowerCase() === "trix-editor") {
    const sel = window.getSelection()
    if (sel && sel.rangeCount > 0) {
      const range = sel.getRangeAt(0).cloneRange()
      range.collapse(true)
      const rect = range.getBoundingClientRect()
      if (rect.top !== 0) {
        dropdown.style.top  = `${rect.bottom + window.scrollY + 6}px`
        dropdown.style.left = `${rect.left   + window.scrollX}px`
        return
      }
    }
    // fallback
    const r = editor.getBoundingClientRect()
    dropdown.style.top  = `${r.bottom + window.scrollY + 6}px`
    dropdown.style.left = `${r.left   + window.scrollX}px`
    return
  }

  // Textarea: mirror div with corrected coordinate calculation
  const coords = getCaretCoordinates(editor)
  const rect   = editor.getBoundingClientRect()

  let top  = rect.top  + window.scrollY + coords.top  + coords.height + 6
  let left = rect.left + window.scrollX + coords.left

  // Keep dropdown inside viewport horizontally
  const dropW = 300
  if (left + dropW > window.innerWidth) left = window.innerWidth - dropW - 12

  dropdown.style.top  = `${top}px`
  dropdown.style.left = `${left}px`
}

function getCaretCoordinates(textarea) {
  const pos   = textarea.selectionStart
  const style = window.getComputedStyle(textarea)

  const mirror = document.createElement("div")
  const props  = [
    "boxSizing", "width", "height", "overflowX", "overflowY",
    "borderTopWidth", "borderRightWidth", "borderBottomWidth", "borderLeftWidth",
    "paddingTop", "paddingRight", "paddingBottom", "paddingLeft",
    "fontStyle", "fontVariant", "fontWeight", "fontStretch",
    "fontSize", "fontSizeAdjust", "lineHeight", "fontFamily",
    "textAlign", "textTransform", "textIndent", "textDecoration",
    "letterSpacing", "wordSpacing", "whiteSpace", "wordWrap"
  ]

  mirror.style.position   = "absolute"
  mirror.style.visibility = "hidden"
  mirror.style.top        = "0"
  mirror.style.left       = "-9999px"
  mirror.style.whiteSpace = "pre-wrap"
  mirror.style.wordWrap   = "break-word"

  props.forEach(p => mirror.style[p] = style[p])

  // Text before caret
  mirror.textContent = textarea.value.substring(0, pos)

  // Caret marker
  const caret = document.createElement("span")
  caret.textContent = "\u200b"   // zero-width space
  mirror.appendChild(caret)

  document.body.appendChild(mirror)

  const coords = {
    top:    caret.offsetTop  - textarea.scrollTop,
    left:   caret.offsetLeft,
    height: parseInt(style.lineHeight) || caret.offsetHeight
  }

  document.body.removeChild(mirror)
  return coords
}

  // ─── Keyboard nav ───────────────────────────────────────────────
  function handleKeydown(e, editor) {
    const dropdown = document.getElementById("mention-dropdown")
    if (!dropdown || dropdown.style.display === "none") return
    const items = dropdown.querySelectorAll(".mention-item")
    if (!items.length) return

    if      (e.key === "ArrowDown")  { e.preventDefault(); setActive(Math.min(activeIndex + 1, items.length - 1)) }
    else if (e.key === "ArrowUp")    { e.preventDefault(); setActive(Math.max(activeIndex - 1, 0)) }
    else if (e.key === "Enter" || e.key === "Tab") {
      if (activeIndex >= 0) {
        e.preventDefault()
        const username = items[activeIndex].querySelector(".mention-username").textContent.slice(1)
        insertMention(editor, username)
      }
    }
    else if (e.key === "Escape") closeDropdown()
  }

  function setActive(index) {
    document.querySelectorAll(".mention-item").forEach(el => el.classList.remove("active"))
    activeIndex = index
    const items = document.querySelectorAll(".mention-item")
    if (items[index]) {
      items[index].classList.add("active")
      items[index].scrollIntoView({ block: "nearest" })
    }
  }

  // ─── Insert mention ─────────────────────────────────────────────
  function insertMention(editor, username) {
    if (editor.tagName.toLowerCase() === "trix-editor") {
      const trix = editor.editor
      const str  = trix.getDocument().toString()
      const atIndex = str.lastIndexOf("@")
      if (atIndex >= 0) {
        trix.setSelectedRange([atIndex, str.length - 1])
        trix.insertString(`@${username} `)
      }
    } else {
      const pos  = editor.selectionStart
      const text = editor.value
      const before = text.substring(0, pos).replace(/@\w*$/, `@${username} `)
      editor.value = before + text.substring(pos)
      editor.selectionStart = editor.selectionEnd = before.length
    }
    closeDropdown()
    editor.focus()
  }

  // ─── Helpers ────────────────────────────────────────────────────
  function getOrCreateDropdown() {
    let el = document.getElementById("mention-dropdown")
    if (!el) {
      el = document.createElement("div")
      el.id = "mention-dropdown"
      document.body.appendChild(el)
    }
    return el
  }

  function closeDropdown() {
    const el = document.getElementById("mention-dropdown")
    if (el) el.style.display = "none"
    activeIndex = -1
  }

  function escapeHtml(str = "") {
    return String(str).replace(/[&<>"']/g, c => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
    }[c]))
  }

  document.addEventListener("click", (e) => {
    if (!e.target.closest("#mention-dropdown") && !e.target.closest("textarea, trix-editor")) {
      closeDropdown()
    }
  })

  attachToEditors()
  window.mentionsAttachToEditors = attachToEditors
})