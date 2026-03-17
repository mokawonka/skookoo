document.addEventListener("turbo:load", () => {

const input = document.getElementById("mainsearchinput")
const results = document.getElementById("search-results")
const container = document.getElementById("search-container")

if(!input) return

let controller

input.addEventListener("input", async () => {

    const q = input.value.trim()

    if(q.length < 2){
        results.innerHTML = ""
        container.classList.remove("active")
        return
    }

    if(controller) controller.abort()
    controller = new AbortController()

    try {

        const res = await fetch(`/search/live?q=${encodeURIComponent(q)}`, {
            signal: controller.signal
        })

        const html = await res.text()

        results.innerHTML = html

        if(html.trim().length === 0){
            container.classList.remove("active")
        } else {
            container.classList.add("active")
        }

    } catch(e) {
        if(e.name !== "AbortError"){
            console.error(e)
        }
    }

})

let selectedIndex = -1;

input.addEventListener("input", () => {
  selectedIndex = -1;
});

input.addEventListener("keydown", function(e) {
  var items = results.querySelectorAll("a, [data-url]");
  if (!items.length) return;

  if (e.key === "ArrowDown") {
    e.preventDefault();
    selectedIndex = Math.min(selectedIndex + 1, items.length - 1);
  } else if (e.key === "ArrowUp") {
    e.preventDefault();
    selectedIndex = Math.max(selectedIndex - 1, 0);
  } else if (e.key === "Enter" && selectedIndex >= 0) {
    e.preventDefault();
    items[selectedIndex].click();
    return;
  } else {
    return;
  }

  items.forEach(function(item, i) {
    item.classList.toggle("search-result-active", i === selectedIndex);
  });

  items[selectedIndex].scrollIntoView({ block: "nearest", behavior: "smooth" });
});

document.addEventListener("click", e => {
    if(!container.contains(e.target)){
        container.classList.remove("active")
    }
})

})