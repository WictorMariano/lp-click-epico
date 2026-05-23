const header = document.querySelector('.header');
const menuToggle = document.querySelector('.menu-toggle');
window.addEventListener('scroll', () => {
    header.classList.toggle('is-scrolled', window.scrollY > 20);
}, { passive: true });

menuToggle?.addEventListener('click', () => {
    const isOpen = header.classList.toggle('is-menu-open');
    menuToggle.setAttribute('aria-expanded', String(isOpen));
});

document.addEventListener('click', (e) => {
    if (!header.contains(e.target)) {
        header.classList.remove('is-menu-open');
        menuToggle?.setAttribute('aria-expanded', 'false');
    }
});

const pricingSection = document.querySelector('.pricing');const pricingToggleBtns = document.querySelectorAll('.pricing-toggle__btn');

pricingToggleBtns.forEach((btn) => {
    btn.addEventListener('click', () => {
        const billing = btn.dataset.billing;
        if (!billing || !pricingSection) return;

        pricingSection.dataset.billing = billing;
        pricingToggleBtns.forEach((b) => {
            const active = b === btn;
            b.classList.toggle('is-active', active);
            b.setAttribute('aria-pressed', String(active));
        });
    });
});
