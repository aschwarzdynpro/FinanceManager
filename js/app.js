'use strict';

// ─── State ───────────────────────────────────────────────────────────────────

const state = {
  view: 'dashboard',  // 'dashboard' | 'monthly' | 'goals'
  year: new Date().getFullYear(),
  month: new Date().getMonth() + 1,
  sidebarOpen: true,
};

// ─── DOM refs ─────────────────────────────────────────────────────────────────

const mainContent   = () => document.getElementById('main-content');
const sidebar       = () => document.getElementById('sidebar');
const sidebarList   = () => document.getElementById('sidebar-list');
const yearSelect    = () => document.getElementById('year-select');

// ─── Router ───────────────────────────────────────────────────────────────────

function navigate(view, year, month) {
  state.view  = view;
  state.year  = year  ?? state.year;
  state.month = month ?? state.month;
  renderAll();
}

// ─── Render ───────────────────────────────────────────────────────────────────

function renderAll() {
  renderSidebar();
  renderMain();
}

function renderSidebar() {
  const years = store.availableYears;

  // Populate year selector in header
  const ys = yearSelect();
  if (ys) {
    ys.innerHTML = years.map(y =>
      `<option value="${y}" ${y === state.year ? 'selected' : ''}>${y}</option>`
    ).join('');
  }

  let html = `
    <li class="sidebar-item ${state.view === 'dashboard' ? 'active' : ''}"
        onclick="navigate('dashboard',${state.year})">
      <span class="sidebar-icon">🏠</span>
      <span>Übersicht</span>
    </li>
    <li class="sidebar-item ${state.view === 'goals' ? 'active' : ''}"
        onclick="navigate('goals',${state.year})">
      <span class="sidebar-icon">🎯</span>
      <span>Jahresziele ${state.year}</span>
    </li>
    <li class="sidebar-section-header">Monate</li>
  `;

  years.forEach(y => {
    const yearEntries = store.entries.filter(e => e.year === y);
    const yearIncome  = store.annualIncome(y);
    html += `
      <li class="sidebar-year-header">
        <span>${y}</span>
        ${yearIncome > 0 ? `<span class="muted small">${fmt(yearIncome)}</span>` : ''}
      </li>`;
    yearEntries.forEach(e => {
      const isActive = state.view === 'monthly' && state.year === e.year && state.month === e.month;
      html += `
        <li class="sidebar-item sidebar-month ${isActive ? 'active' : ''}"
            onclick="navigate('monthly',${e.year},${e.month})">
          <span class="sidebar-icon">📅</span>
          <div class="sidebar-month-info">
            <span>${MONTH_NAMES[e.month-1]} ${e.year}</span>
            ${e.income > 0 ? `<span class="muted small">${fmt(e.income)}</span>` : ''}
          </div>
        </li>`;
    });
  });

  sidebarList().innerHTML = html;
}

function renderMain() {
  let html = '';
  if (state.view === 'dashboard') html = renderDashboard(state.year);
  else if (state.view === 'monthly') html = renderMonthly(state.year, state.month);
  else if (state.view === 'goals') html = renderGoals(state.year);

  mainContent().innerHTML = html;
  attachEventListeners();
}

// ─── Event Listeners ─────────────────────────────────────────────────────────

function attachEventListeners() {
  // Income input (monthly view)
  document.querySelectorAll('input[data-field="income"]').forEach(input => {
    input.addEventListener('change', () => {
      const entry = store.getEntry(state.year, state.month)
        || { year: state.year, month: state.month, income: 0, notes: '',
             allocations: CATEGORIES.map(c=>({categoryId:c.id,planned:0,actual:0})) };
      entry.income = parseAmount(input.value);
      store.upsertEntry(entry);
      renderAll();
    });
  });

  // Allocation inputs (monthly view)
  document.querySelectorAll('input.alloc-input').forEach(input => {
    input.addEventListener('change', () => {
      const catId = input.dataset.cat;
      const field = input.dataset.field;
      const entry = store.getEntry(state.year, state.month)
        || store._newEntry(state.year, state.month);
      const alloc = entry.allocations.find(a => a.categoryId === catId);
      if (alloc) {
        alloc[field] = parseAmount(input.value);
        store.upsertEntry(entry);
        renderAll();
      }
    });
  });

  // Goal inputs (goals view)
  document.querySelectorAll('input.goal-input').forEach(input => {
    input.addEventListener('change', () => {
      const catId = input.dataset.cat;
      const year  = parseInt(input.dataset.year);
      store.setGoal(year, catId, parseAmount(input.value));
      renderAll();
    });
  });
}

// ─── Sidebar toggle ──────────────────────────────────────────────────────────

function toggleSidebar() {
  state.sidebarOpen = !state.sidebarOpen;
  sidebar().classList.toggle('collapsed', !state.sidebarOpen);
  document.getElementById('app').classList.toggle('sidebar-collapsed', !state.sidebarOpen);
}

// ─── Add Month Modal ─────────────────────────────────────────────────────────

function openAddMonth() {
  document.getElementById('modal-overlay').classList.remove('hidden');
  const now = new Date();
  document.getElementById('modal-year').value  = now.getFullYear();
  document.getElementById('modal-month').value = now.getMonth() + 1;
}

function closeModal() {
  document.getElementById('modal-overlay').classList.add('hidden');
}

function confirmAddMonth() {
  const y = parseInt(document.getElementById('modal-year').value);
  const m = parseInt(document.getElementById('modal-month').value);
  store.addMonth(y, m);
  closeModal();
  navigate('monthly', y, m);
}

// ─── Year select ─────────────────────────────────────────────────────────────

function onYearChange(val) {
  state.year = parseInt(val);
  if (state.view === 'monthly') {
    // pick last available month in that year, or stay
    const available = store.entries.filter(e => e.year === state.year);
    if (available.length) state.month = available[0].month;
  }
  renderAll();
}

// ─── Init ─────────────────────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', () => {
  renderAll();
});
