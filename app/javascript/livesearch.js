document.addEventListener("turbo:load", () => {

  const input     = document.getElementById("mainsearchinput")
  const results   = document.getElementById("search-results")
  const container = document.getElementById("search-container")

  if (!input) return

  // ── History helpers ───────────────────────────────────────────────
  const HISTORY_KEY = "search_history_people"
  const MAX_HISTORY = 5

  function getHistory() {
    try { return JSON.parse(localStorage.getItem(HISTORY_KEY)) || [] }
    catch { return [] }
  }

  function saveToHistory(user) {
    let h = getHistory().filter(u => u.username !== user.username)
    h.unshift(user)
    localStorage.setItem(HISTORY_KEY, JSON.stringify(h.slice(0, MAX_HISTORY)))
  }

  function removeFromHistory(username) {
    localStorage.setItem(
      HISTORY_KEY,
      JSON.stringify(getHistory().filter(u => u.username !== username))
    )
  }

  function escapeHtml(str) {
    return String(str ?? "")
      .replace(/&/g, "&amp;").replace(/</g, "&lt;")
      .replace(/>/g, "&gt;").replace(/"/g, "&quot;")
  }

  function renderHistory() {
    const history = getHistory()
    if (!history.length) {
      results.innerHTML = ""
      container.classList.remove("active")
      return
    }

    const items = history.map(u => {
      const avatar = u.avatarUrl
        ? `<img src="${escapeHtml(u.avatarUrl)}" alt="">`
        : `<img src="/assets/default-avatar.svg" alt="">`

      return `
        <a href="/users/${escapeHtml(u.username)}"
          class="search-item search-user"
          data-history-item
          data-username="${escapeHtml(u.username)}">
          <div class="search-user-avatar">${avatar}</div>
          <div class="search-user-meta">
            <div class="search-user-name">${escapeHtml(u.name)}</div>
            <div class="search-user-handle">@${escapeHtml(u.username)}</div>
          </div>
          <button class="search-history-remove"
                  data-remove="${escapeHtml(u.username)}"
                  title="Remove" aria-label="Remove from history">×</button>
        </a>`
    }).join("")

    results.innerHTML = `
      <div class="search-section">
        <div class="search-section-header">
          <div class="search-section-title">Recent</div>
          <button class="search-history-clear" data-clear-all>Clear all</button>
        </div>
        ${items}
      </div>`

    container.classList.add("active")
  }

  // ── Show history on focus when query is short ─────────────────────
  input.addEventListener("focus", () => {
    if (input.value.trim().length < 2) renderHistory()
  })

  // ── Intercept clicks inside results ──────────────────────────────
  results.addEventListener("click", e => {

    // Clear all button
    const clearBtn = e.target.closest("[data-clear-all]")
    if (clearBtn) {
      e.preventDefault()
      localStorage.removeItem(HISTORY_KEY)
      results.innerHTML = ""
      container.classList.remove("active")
      return
    }

    // Remove single item
    const removeBtn = e.target.closest("[data-remove]")
    if (removeBtn) {
      e.preventDefault()
      e.stopPropagation()
      removeFromHistory(removeBtn.dataset.remove)
      renderHistory()
      return
    }

    // Save user to history when a live-search user row is clicked
    const userLink = e.target.closest(".search-user")
    if (userLink && !userLink.dataset.historyItem) {
      const handleEl  = userLink.querySelector(".search-user-handle")
      const nameEl    = userLink.querySelector(".search-user-name")
      const imgEl     = userLink.querySelector(".search-user-avatar img")

      const username  = handleEl?.textContent?.replace("@", "").trim()
      const name      = nameEl?.childNodes[0]?.textContent?.trim() || username
      const avatarUrl = imgEl?.src || null

      if (username) saveToHistory({ username, name, avatarUrl })
    }
  })

  // ── Live search ───────────────────────────────────────────────────
  let controller
  let selectedIndex = -1

  input.addEventListener("input", async () => {
    const q = input.value.trim()
    selectedIndex = -1

    if (q.length < 2) {
      results.innerHTML = ""
      container.classList.remove("active")
      renderHistory()
      return
    }

    if (controller) controller.abort()
    controller = new AbortController()

    try {
      const res  = await fetch(`/search/live?q=${encodeURIComponent(q)}`, {
        signal: controller.signal
      })
      const html = await res.text()
      results.innerHTML = html

      if (html.trim().length === 0) container.classList.remove("active")
      else                          container.classList.add("active")

    } catch(e) {
      if (e.name !== "AbortError") console.error(e)
    }
  })

  // ── Keyboard navigation ───────────────────────────────────────────
  input.addEventListener("keydown", function(e) {
    const items = results.querySelectorAll("a, [data-url]")
    if (!items.length) return

    if (e.key === "ArrowDown") {
      e.preventDefault()
      selectedIndex = Math.min(selectedIndex + 1, items.length - 1)
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      selectedIndex = Math.max(selectedIndex - 1, 0)
    } else if (e.key === "Enter" && selectedIndex >= 0) {
      e.preventDefault()
      items[selectedIndex].click()
      return
    } else {
      return
    }

    items.forEach((item, i) =>
      item.classList.toggle("search-result-active", i === selectedIndex)
    )
    items[selectedIndex].scrollIntoView({ block: "nearest", behavior: "smooth" })
  })

  // ── Close on outside click ────────────────────────────────────────
  document.addEventListener("click", e => {
    if (!container.contains(e.target)) container.classList.remove("active")
  })

})