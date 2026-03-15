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

document.addEventListener("click", e => {
    if(!container.contains(e.target)){
        container.classList.remove("active")
    }
})

})