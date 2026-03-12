document.addEventListener("turbo:load", function () {

  let dictionaryAbort = null
  let currentSearchId = 0
  const CACHE          = new Map()
  const TRANSLATE_CACHE = new Map()

  const popup      = document.getElementById("dictionary-popup")
  const input      = document.getElementById("dictionary-input")
  const results    = document.getElementById("dictionary-results")
  const status     = document.getElementById("dictionary-status")
  const langSelect = document.getElementById("dictionary-lang")
  const closeBtn   = document.getElementById("dictionary-close")
  const toggleBtn  = document.getElementById("dictionary-toggle")

  if (!popup || !input || !results || !status || !langSelect) return

  const EMAIL = popup.dataset.userEmail || ""

  const TRANSLATION_TIMEOUT_MS = 6000
  const FULL_FETCH_TIMEOUT_MS  = 9000

  const SUPPORTED_LANGS = ["en", "fr", "es", "it", "de"]

  const LANG_NAMES = {
    en: "English",
    fr: "Français",
    es: "Español",
    it: "Italiano",
    de: "Deutsch"
  }

  /* -------------------------------------------------- */
  /* TRANSLATION (MyMemory)                             */
  /* -------------------------------------------------- */

  async function translateText(text, fromLang, toLang, signal) {
    if (fromLang === toLang || !text?.trim()) return text

    const cacheKey = `${fromLang}|${toLang}|${text.trim()}`
    if (TRANSLATE_CACHE.has(cacheKey)) return TRANSLATE_CACHE.get(cacheKey)

    let url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${fromLang}|${toLang}`
    if (EMAIL) url += `&de=${encodeURIComponent(EMAIL)}`

    const timeout = new Promise((_, reject) =>
      setTimeout(() => reject(new Error("timeout")), TRANSLATION_TIMEOUT_MS)
    )

    try {
      const res = await Promise.race([fetch(url, { signal }), timeout])
      if (!res.ok) return text
      const data = await res.json()
      const translated = data?.responseData?.translatedText || text
      TRANSLATE_CACHE.set(cacheKey, translated)
      return translated
    } catch {
      return text
    }
  }

  /* -------------------------------------------------- */
  /* WORDNET LOOKUP (local Rails endpoint)              */
  /* -------------------------------------------------- */

  async function fetchWordNet(word, signal) {
    const res = await fetch(
      `/dictionary/lookup?word=${encodeURIComponent(word)}`,
      { signal }
    )
    if (res.status === 404) return null
    if (!res.ok) throw new Error("WordNet error")
    return await res.json()
  }

  /* -------------------------------------------------- */
  /* MAIN SEARCH                                        */
  /* -------------------------------------------------- */

  async function searchDictionary(word) {
    results.innerHTML = ""
    status.innerHTML  = ""

    if (!word?.trim()) return

    const originalWord = word.trim()
    const lang         = langSelect.value

    if (!SUPPORTED_LANGS.includes(lang)) {
      status.innerHTML = "Language not supported"
      return
    }

    currentSearchId++
    const searchId = currentSearchId

    if (dictionaryAbort) dictionaryAbort.abort()
    dictionaryAbort = new AbortController()
    const { signal } = dictionaryAbort

    const timeoutId = setTimeout(() => {
      dictionaryAbort.abort()
      if (searchId !== currentSearchId) return
      status.innerHTML  = "Search timeout"
      results.innerHTML = ""
    }, FULL_FETCH_TIMEOUT_MS)

    let lookupWord = originalWord
      .toLowerCase()
      .replace(/[^a-zà-ÿ\-']/gi, "")
      .trim()

    const cacheKey = `${lang}:${lookupWord}`

    if (CACHE.has(cacheKey)) {
      clearTimeout(timeoutId)
      status.innerHTML  = ""
      results.innerHTML = CACHE.get(cacheKey)
      return
    }

    try {

      /* --- Step 1: translate query to English if needed --- */

      if (lang !== "en") {
        status.innerHTML = "Translating..."

        lookupWord = await translateText(originalWord, lang, "en", signal)
        if (signal.aborted || searchId !== currentSearchId) return

        lookupWord = lookupWord
          .toLowerCase()
          .split(/[\s,.;:!?]/)[0]
          .replace(/[^a-z\-']/g, "")
      }

      /* --- Step 2: WordNet lookup (local) --- */

      status.innerHTML = "Fetching definition..."

      const defData = await fetchWordNet(lookupWord, signal)
      if (signal.aborted || searchId !== currentSearchId) return

      if (!defData) {
        status.innerHTML  = ""
        results.innerHTML = `
          <div style="color:#dc3545;padding:60px 0;text-align:center;font-size:1.15em;">
            Word not found<br><strong>«${originalWord}»</strong>
          </div>`
        return
      }

      /* --- Step 3: render (with translation if needed) --- */

      const html = await renderDictionary(defData, originalWord, lang, signal)
      if (signal.aborted || searchId !== currentSearchId) return

      results.innerHTML = html
      status.innerHTML  = ""

      CACHE.set(cacheKey, html)

    } catch {
      if (signal.aborted || searchId !== currentSearchId) return
      status.innerHTML  = "Network error"
      results.innerHTML = `
        <div style="color:#dc3545;padding:60px 0;text-align:center;">
          Network error — try again later
        </div>`
    } finally {
      clearTimeout(timeoutId)
    }
  }

  /* -------------------------------------------------- */
  /* RENDER                                             */
  /* -------------------------------------------------- */

  async function renderDictionary(defData, originalWord, targetLang, signal) {
    let html = `<div class="dict-word">${originalWord}</div>`

    if (defData.phonetic) {
      html += `<div class="dict-phonetic">${defData.phonetic}</div>`
    }

    if (targetLang !== "en") {
      html += `<div class="dict-translation"><small>(translated to ${LANG_NAMES[targetLang]})</small></div>`
    }

    const meanings = (defData.meanings || []).slice(0, 2)

    if (targetLang === "en") {

      /* English — no translation needed, render directly */

      for (const meaning of meanings) {
        html += `<div class="dict-pos"><em>${meaning.partOfSpeech || ""}</em></div>`
        for (const def of (meaning.definitions || []).slice(0, 2)) {
          html += `<div class="dict-definition">${def.definition || ""}</div>`
          if (def.example) {
            html += `<div class="dict-example"><em>"${def.example}"</em></div>`
          }
        }
      }

    } else {

      /* Non-English — translate all strings in parallel */

      const posPromises = meanings.map(m =>
        translateText(m.partOfSpeech || "", "en", targetLang, signal)
      )

      const defPromises = []
      const defCounts   = []

      for (const meaning of meanings) {
        const slice = (meaning.definitions || []).slice(0, 2)
        defCounts.push(slice.length)
        for (const def of slice) {
          defPromises.push(translateText(def.definition || "", "en", targetLang, signal))
        }
      }

      const allTranslated = await Promise.all([...posPromises, ...defPromises])
      if (signal.aborted) return ""

      let idx = meanings.length // pos translations occupy first N slots

      for (let m = 0; m < meanings.length; m++) {
        html += `<div class="dict-pos"><em>${allTranslated[m]}</em></div>`
        for (let d = 0; d < defCounts[m]; d++) {
          html += `<div class="dict-definition">${allTranslated[idx++]}</div>`
        }
      }

    }

    /* Synonyms (from WordNet, translated if needed) */

    const allSyns = meanings.flatMap(m => m.synonyms || []).slice(0, 6)

    if (allSyns.length) {
      let syns = allSyns.slice(0, 4)

      if (targetLang !== "en") {
        syns = await Promise.all(
          syns.map(s => translateText(s, "en", targetLang, signal))
        )
      }

      html += `
        <div class="dict-synonyms">
          <b>${targetLang === "en" ? "Synonyms" : "Synonymes"}:</b> ${syns.join(", ")}
        </div>`
    }

    /* Add to vocabulary button */

    if (EMAIL) {
      const firstDef = defData.meanings?.[0]?.definitions?.[0]?.definition || ""
      html += `
        <div class="dict-actions">
          <button class="dict-add-vocab"
                  data-origin="dictionary"
                  data-word="${originalWord}"
                  data-definition="${firstDef.replace(/"/g, '&quot;')}">
            + Add to vocabulary
          </button>
        </div>`
    }

    return html
  }

  /* -------------------------------------------------- */
  /* EVENTS                                             */
  /* -------------------------------------------------- */

  input.addEventListener("keydown", function (e) {
    if (e.key === "Enter") {
      e.preventDefault()
      const word = this.value.trim()
      if (word) searchDictionary(word)
    }
  })

  input.addEventListener("input", function () {
    if (!this.value.trim()) {
      results.innerHTML = ""
      status.innerHTML  = ""
    }
  })

  if (closeBtn) closeBtn.addEventListener("click", () => popup.classList.add("dictionary-hidden"))

  if (toggleBtn) {
    toggleBtn.addEventListener("click", () => {
      popup.classList.toggle("dictionary-hidden")
      if (!popup.classList.contains("dictionary-hidden")) input.focus()
    })
  }

  document.addEventListener("keydown", function (e) {
    if (e.ctrlKey && e.key === "d") {
      e.preventDefault()
      popup.classList.remove("dictionary-hidden")
      input.focus()
    }
  })

  /* Add to vocabulary */

  document.addEventListener("click", async function (e) {
    const btn = e.target.closest(".dict-add-vocab")
    if (!btn) return

    const form = document.getElementById("dictionary-vocab-form")
    if (!form) return

    document.getElementById("vocab-word").value       = btn.dataset.word
    document.getElementById("vocab-definition").value = btn.dataset.definition
    document.getElementById("vocab-origin").value     = btn.dataset.origin

    const formData = new FormData(form)

    try {
      const response = await fetch(form.action, {
        method:  "POST",
        body:    formData,
        headers: {
          "X-Requested-With": "XMLHttpRequest",
          "Accept":           "application/json"
        }
      })

      if (response.ok) {
        const data = await response.json()
        if (data.success) {
          btn.innerHTML = "✓ Added"
          btn.disabled  = true
        }
      } else {
        const err = await response.json()
        alert("Error: " + (err.error || "Failed to add"))
      }
    } catch {
      alert("Network error – please try again")
    }
  })

})