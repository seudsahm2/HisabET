(() => {
  const items = document.querySelectorAll(".reveal");

  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add("in-view");
          observer.unobserve(entry.target);
        }
      }
    },
    { threshold: 0.15, rootMargin: "0px 0px -8% 0px" },
  );

  items.forEach((item) => observer.observe(item));

  const cards = document.querySelectorAll(
    ".floating-chip, .glass-card, .feature-card, .page-card, .policy-card",
  );
  document.addEventListener("pointermove", (event) => {
    const x = (event.clientX / window.innerWidth - 0.5) * 12;
    const y = (event.clientY / window.innerHeight - 0.5) * 12;
    cards.forEach((card, index) => {
      const factor = ((index % 4) + 1) * 0.15;
      card.style.transform = `translate3d(${x * factor}px, ${y * factor}px, 0)`;
    });
  });
})();
