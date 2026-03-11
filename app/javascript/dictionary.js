document.addEventListener("turbo:load", function () {

  let dictionaryAbort = null;

  const popup       = document.getElementById("dictionary-popup");
  const input       = document.getElementById("dictionary-input");
  const results     = document.getElementById("dictionary-results");
  const status      = document.getElementById("dictionary-status");
  const langSelect  = document.getElementById("dictionary-lang");
  const closeBtn    = document.getElementById("dictionary-close");
  const toggleBtn   = document.getElementById("dictionary-toggle");

  if (!popup || !input || !results || !status || !langSelect) return;

  const MYMEMORY_EMAIL = popup.dataset.userEmail || "";
  let last429Time = 0;
  const MIN_DELAY_AFTER_429 = 15000;
  const TRANSLATION_TIMEOUT_MS = 7000;
  const FULL_FETCH_TIMEOUT_MS  = 15000; // increased to 15s for common words

  const SUPPORTED_LANGS = ["en", "fr", "es", "it", "de"];

  const MESSAGES = {
    en: {
      searching:        "Looking up definition...",
      translating:      "Translating...",
      translatingToEn:  "Translating to English...",
      fetchingDef:      "Fetching definition...",
      preparing:        "Preparing display...",
      addingSynonyms:   "Adding synonyms...",
      noResults:        "No definition found",
      wordNotFound:     "Word not found in dictionary",
      errorNetwork:     "Network error — try again later",
      loading:          "Loading...",
      noDefinitionFor:  "No definition found for",
      rateLimited:      "Translation limit reached — showing English only. Try again in 1 min.",
      timeout:          "Translation timed out — showing original English.",
      fullTimeout:      "Search is taking too long — network issue? Try again."
    },
    fr: {
      searching:        "Recherche de la définition...",
      translating:      "Traduction en cours...",
      translatingToEn:  "Traduction vers l'anglais...",
      fetchingDef:      "Récupération de la définition...",
      preparing:        "Préparation de l'affichage...",
      addingSynonyms:   "Ajout des synonymes...",
      noResults:        "Aucun résultat trouvé",
      wordNotFound:     "Mot non trouvé dans le dictionnaire",
      errorNetwork:     "Erreur réseau — réessayez plus tard",
      loading:          "Chargement en cours...",
      noDefinitionFor:  "Aucune définition trouvée pour",
      rateLimited:      "Limite de traduction atteinte — affichage en anglais uniquement. Réessayez dans 1 min.",
      timeout:          "Traduction expirée — affichage de l'anglais original.",
      fullTimeout:      "La recherche prend trop de temps — problème réseau ? Réessayez."
    },
    // Add es/it/de if needed — fallback to en otherwise
  };

  const LANG_NAMES = {
    en: "English", fr: "Français", es: "Español", it: "Italiano", de: "Deutsch"
  };

  function getMsg(lang, key) {
    return MESSAGES[lang]?.[key] || MESSAGES.en[key] || key;
  }

  async function translateText(text, fromLang, toLang, signal, skipIfLimited = false) {
    if (skipIfLimited) return { text, isFallback: true };
    if (fromLang === toLang || !text?.trim()) return { text, isFallback: false };

    const now = Date.now();
    if (now - last429Time < MIN_DELAY_AFTER_429) {
      return { text, isFallback: true };
    }

    const pair = `${fromLang}|${toLang}`;
    let url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${pair}`;
    if (MYMEMORY_EMAIL) url += `&de=${encodeURIComponent(MYMEMORY_EMAIL)}`;

    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error("Translation timeout")), TRANSLATION_TIMEOUT_MS)
    );

    try {
      const res = await Promise.race([fetch(url, { signal }), timeoutPromise]);

      if (res.status === 429) {
        last429Time = Date.now();
        return { text, isFallback: true };
      }

      if (!res.ok) return { text, isFallback: true };

      const data = await res.json();
      const translated = data?.responseData?.translatedText?.trim() || text;
      return { text: translated, isFallback: false };
    } catch {
      return { text, isFallback: true };
    }
  }

  async function searchDictionary(word) {
    // Clear everything first
    results.innerHTML = "";
    status.innerHTML = "";

    if (!word?.trim()) return;

    const originalWord = word.trim();
    const lang = langSelect.value;

    if (!SUPPORTED_LANGS.includes(lang)) {
      status.innerHTML = "Langue non supportée.";
      return;
    }

    status.innerHTML = getMsg(lang, lang === "en" ? "searching" : "translating");

    if (dictionaryAbort) dictionaryAbort.abort();
    dictionaryAbort = new AbortController();
    const { signal } = dictionaryAbort;

    let lookupWord = originalWord.toLowerCase().replace(/[^a-zà-ÿ\-']/gi, "").trim();

    let enEquivalent = originalWord;
    if (lang !== "en") {
      status.innerHTML = getMsg(lang, "translatingToEn");
      const { text } = await translateText(originalWord, lang, "en", signal);
      enEquivalent = text.toLowerCase().split(/[\s,.;:!?]/)[0].replace(/[^a-z\-']/g, "");
    }

    const finalLookup = lang === "en" ? lookupWord : (enEquivalent || lookupWord);

    status.innerHTML = getMsg(lang, "fetchingDef");

    let defData = null;
    let synData = [];

    const fullTimeoutId = setTimeout(() => {
      status.innerHTML = getMsg(lang, "fullTimeout");
      results.innerHTML = ""; // important: clear loading spinner
    }, FULL_FETCH_TIMEOUT_MS);

    try {
      const defRes = await fetch(`https://api.dictionaryapi.dev/api/v2/entries/en/${encodeURIComponent(finalLookup)}`, { signal });

      if (defRes.status === 404) {
        clearTimeout(fullTimeoutId);
        status.innerHTML = "";
        results.innerHTML = `
          <div style="color:#dc3545;padding:60px 0;text-align:center;font-size:1.15em;">
            ${getMsg(lang, "wordNotFound")}<br>
            <strong>«${originalWord}»</strong>
          </div>`;
        return;
      }

      if (!defRes.ok) throw new Error(`Dictionary API: ${defRes.status}`);

      defData = await defRes.json();

      const synRes = await fetch(`https://api.datamuse.com/words?rel_syn=${encodeURIComponent(finalLookup)}`, { signal });
      if (synRes.ok) {
        const synJson = await synRes.json();
        synData = synJson.slice(0, 6).map(item => item.word); // reduced further
      }
    } catch (err) {
      clearTimeout(fullTimeoutId);
      status.innerHTML = getMsg(lang, "errorNetwork");
      results.innerHTML = `<div style="color:#dc3545;padding:60px 0;text-align:center;">
        ${getMsg(lang, "errorNetwork")}
      </div>`;
      return;
    }

    clearTimeout(fullTimeoutId);

    if (!defData || !Array.isArray(defData) || defData.length === 0) {
      status.innerHTML = "";
      results.innerHTML = `
        <div style="color:#dc3545;padding:60px 0;text-align:center;font-size:1.15em;">
          ${getMsg(lang, "noDefinitionFor")}<br><strong>«${originalWord}»</strong>
        </div>`;
      return;
    }

    await renderDictionary(defData, synData, originalWord, lang, finalLookup, signal);

    status.innerHTML = "";
  }

  async function renderDictionary(defData, synData, originalWord, targetLang, lookedUpWord, signal) {
    results.innerHTML = ""; // ensure loading is gone
    let html = `<div class="dict-word">${originalWord}</div>`;
    let isRateLimited = false;
    let fallbackCount = 0;

    if (targetLang !== "en") {
      html += `<div class="dict-translation"><small>(définition traduite en ${LANG_NAMES[targetLang]})</small></div>`;
    }

    const entry = defData[0];

    if (entry.phonetic) {
      html += `<div class="dict-phonetic">${entry.phonetic}</div>`;
    }

    // Show at least something even if translations are slow
    for (const meaning of (entry.meanings || []).slice(0, 2)) { // limit to 2 meanings
      const posResult = await translateText(meaning.partOfSpeech || "", "en", targetLang, signal, isRateLimited);
      if (posResult.isFallback) { isRateLimited = true; fallbackCount++; }
      html += `<div class="dict-pos"><em>${posResult.text}</em></div>`;

      for (const def of (meaning.definitions || []).slice(0, 2)) {
        let defText = def.definition;
        if (targetLang !== "en") {
          const defResult = await translateText(def.definition, "en", targetLang, signal, isRateLimited);
          defText = defResult.text;
          if (defResult.isFallback) { isRateLimited = true; fallbackCount++; }
        }
        html += `<div class="dict-definition">${defText}</div>`;
      }
    }

    // Skip synonyms & examples when rate-limited or time-sensitive
    if (synData.length > 0 && !isRateLimited && fallbackCount < 3) {
      let translatedSyns = synData.slice(0, 4); // very limited
      if (targetLang !== "en") {
        const synResults = await Promise.all(
          translatedSyns.map(s => translateText(s, "en", targetLang, signal, isRateLimited))
        );
        translatedSyns = synResults.map(r => {
          if (r.isFallback) { isRateLimited = true; fallbackCount++; }
          return r.text;
        });
      }

      const uniqueSyns = [...new Set(translatedSyns.filter(Boolean))];
      if (uniqueSyns.length) {
        html += `
          <div class="dict-synonyms">
            <b>${targetLang === "en" ? "Synonyms" : "Synonymes"} :</b> ${uniqueSyns.join(", ")}
          </div>
        `;
      }
    }

    if (isRateLimited && targetLang !== "en") {
      html += `
        <div style="margin:20px 0; padding:12px; background:#fff3cd; border:1px solid #ffeeba; border-radius:8px; color:#856404; font-size:13px;">
          <strong>Note:</strong> ${getMsg(targetLang, "rateLimited")} (${fallbackCount} traductions omises)
        </div>
      `;
    }

    results.innerHTML = html;
  }

  // ────────────────────────────────────────────────
  // EVENTS
  // ────────────────────────────────────────────────
  input.addEventListener("keydown", function (e) {
    if (e.key === "Enter") {
      e.preventDefault();
      const word = this.value.trim();
      if (word) {
        searchDictionary(word);
      }
    }
  });

  input.addEventListener("input", function () {
    if (!this.value.trim()) {
      results.innerHTML = "";
      status.innerHTML = "";
    }
  });

  if (closeBtn) {
    closeBtn.addEventListener("click", () => popup.classList.add("dictionary-hidden"));
  }

  if (toggleBtn) {
    toggleBtn.addEventListener("click", () => {
      popup.classList.toggle("dictionary-hidden");
      if (!popup.classList.contains("dictionary-hidden")) {
        input.focus();
      }
    });
  }

    document.addEventListener("keydown", function(e){

        if(e.ctrlKey && e.key === "d"){
            e.preventDefault()
            popup.classList.remove("dictionary-hidden")
            input.focus()
        }
    })

});