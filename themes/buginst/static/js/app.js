/* 人型害虫观察站 · 交互：主题切换 / 搜索 / 刑种筛选 / 阅读进度 */
(function () {
  "use strict";

  /* ---------- 主题切换：auto → light → dark ---------- */
  var btn = document.getElementById("themeToggle");
  var icon = document.getElementById("themeIcon");
  var order = ["auto", "light", "dark"];
  function pref() {
    return document.documentElement.getAttribute("data-theme-pref") || "auto";
  }
  function apply(p) {
    var dark = p === "dark" || (p === "auto" && window.matchMedia("(prefers-color-scheme: dark)").matches);
    document.documentElement.setAttribute("data-theme", dark ? "dark" : "light");
    document.documentElement.setAttribute("data-theme-pref", p);
    try { localStorage.setItem("hi-theme", p); } catch (e) {}
    if (icon) icon.textContent = dark ? "☀" : "☾";
  }
  if (btn) {
    btn.addEventListener("click", function () {
      apply(order[(order.indexOf(pref()) + 1) % order.length]);
    });
  }
  apply(pref());

  /* ---------- 搜索 + 刑种筛选 ---------- */
  var search = document.getElementById("search");
  var rows = Array.prototype.slice.call(document.querySelectorAll(".case-row"));
  var chips = Array.prototype.slice.call(document.querySelectorAll(".chip"));
  var count = document.getElementById("count");
  var empty = document.getElementById("empty");
  var activeCat = "all";

  function update() {
    var q = search ? search.value.trim().toLowerCase() : "";
    var n = 0;
    rows.forEach(function (r) {
      var okCat = activeCat === "all" || r.getAttribute("data-cat") === activeCat;
      var okQ = !q || (r.getAttribute("data-search") || "").toLowerCase().indexOf(q) > -1;
      var show = okCat && okQ;
      r.style.display = show ? "" : "none";
      if (show) n++;
    });
    if (count) count.textContent = "共 " + n + " 条";
    if (empty) empty.hidden = n !== 0;
  }
  if (search) search.addEventListener("input", update);
  chips.forEach(function (c) {
    c.addEventListener("click", function () {
      chips.forEach(function (x) { x.classList.remove("active"); });
      c.classList.add("active");
      activeCat = c.getAttribute("data-cat");
      update();
    });
  });
  update();

  /* ---------- 阅读进度条 ---------- */
  var bar = document.getElementById("progress");
  if (bar) {
    var ticking = false;
    function onScroll() {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(function () {
        var h = document.documentElement;
        var max = h.scrollHeight - h.clientHeight;
        bar.style.width = (max > 0 ? (h.scrollTop / max) * 100 : 0) + "%";
        ticking = false;
      });
    }
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
  }
})();
