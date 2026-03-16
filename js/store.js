'use strict';

// ─── Constants ───────────────────────────────────────────────────────────────

const DEFAULT_CATEGORIES = [
  { id: 'etf',     label: 'ETF Sparplan', icon: '📈', color: '#3b82f6' },
  { id: 'urlaub',  label: 'Urlaub',       icon: '✈️',  color: '#f97316' },
  { id: 'auto',    label: 'Auto',         icon: '🚗',  color: '#ef4444' },
  { id: 'aktien',  label: 'Aktien',       icon: '💹',  color: '#22c55e' },
];

const MONTH_NAMES = [
  'Januar','Februar','März','April','Mai','Juni',
  'Juli','August','September','Oktober','November','Dezember'
];

// ─── Store ───────────────────────────────────────────────────────────────────

class Store {
  constructor() {
    this._categories = this._load('fm_categories') || DEFAULT_CATEGORIES;
    this._entries    = this._load('fm_entries')    || [];
    this._goals      = this._load('fm_goals')      || [];
    this._templates  = this._load('fm_templates')  || {};
    this._ensureCurrentMonth();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  _load(key) {
    try { return JSON.parse(localStorage.getItem(key)); } catch { return null; }
  }

  _save() {
    localStorage.setItem('fm_categories', JSON.stringify(this._categories));
    localStorage.setItem('fm_entries',    JSON.stringify(this._entries));
    localStorage.setItem('fm_goals',      JSON.stringify(this._goals));
    localStorage.setItem('fm_templates',  JSON.stringify(this._templates));
  }

  _ensureCurrentMonth() {
    const now = new Date();
    const y = now.getFullYear(), m = now.getMonth() + 1;
    if (!this._entries.find(e => e.year === y && e.month === m)) {
      this._entries.push(this._newEntry(y, m));
      this._save();
    }
  }

  _newEntry(year, month) {
    return {
      id: `${year}-${String(month).padStart(2,'0')}`,
      year, month,
      income: 0,
      notes: '',
      allocations: this._categories.map(c => ({
        categoryId: c.id,
        planned: this._templates[c.id] || 0,
        actual: 0
      }))
    };
  }

  // ── Entries ─────────────────────────────────────────────────────────────────

  get entries() {
    return [...this._entries].sort((a,b) => b.year !== a.year ? b.year - a.year : b.month - a.month);
  }

  getEntry(year, month) {
    return this._entries.find(e => e.year === year && e.month === month) || null;
  }

  upsertEntry(entry) {
    const idx = this._entries.findIndex(e => e.year === entry.year && e.month === entry.month);
    if (idx >= 0) this._entries[idx] = entry; else this._entries.push(entry);
    this._save();
  }

  addMonth(year, month) {
    if (this._entries.find(e => e.year === year && e.month === month)) return;
    this._entries.push(this._newEntry(year, month));
    this._save();
  }

  // ── Goals ───────────────────────────────────────────────────────────────────

  getGoal(year, categoryId) {
    return this._goals.find(g => g.year === year && g.categoryId === categoryId)?.amount || 0;
  }

  setGoal(year, categoryId, amount) {
    const idx = this._goals.findIndex(g => g.year === year && g.categoryId === categoryId);
    if (idx >= 0) this._goals[idx].amount = amount;
    else this._goals.push({ year, categoryId, amount });
    this._save();
  }

  // ── Aggregates ──────────────────────────────────────────────────────────────

  annualIncome(year) {
    return this._entries.filter(e => e.year === year).reduce((s,e) => s + (e.income||0), 0);
  }

  annualTotal(year, categoryId, field) {
    return this._entries
      .filter(e => e.year === year)
      .flatMap(e => e.allocations)
      .filter(a => a.categoryId === categoryId)
      .reduce((s,a) => s + (a[field]||0), 0);
  }

  get availableYears() {
    const years = new Set([
      ...this._entries.map(e => e.year),
      new Date().getFullYear()
    ]);
    return [...years].sort((a,b) => b - a);
  }

  entriesForYear(year) {
    return this._entries
      .filter(e => e.year === year)
      .sort((a,b) => a.month - b.month);
  }

  // ── Templates ───────────────────────────────────────────────────────────────

  getTemplates() { return { ...this._templates }; }

  setTemplate(categoryId, amount) {
    this._templates[categoryId] = amount;
    this._save();
  }

  // ── Categories ──────────────────────────────────────────────────────────────

  getCategories() { return [...this._categories]; }

  addCategory(label, icon, color) {
    const id = 'cat_' + Date.now();
    this._categories.push({ id, label, icon, color });
    this._save();
    return id;
  }

  updateCategory(id, label, icon, color) {
    const idx = this._categories.findIndex(c => c.id === id);
    if (idx >= 0) { this._categories[idx] = { id, label, icon, color }; this._save(); }
  }

  deleteCategory(id) {
    this._categories = this._categories.filter(c => c.id !== id);
    this._save();
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function fmt(value) {
  return new Intl.NumberFormat('de-DE', {
    style: 'currency', currency: 'EUR'
  }).format(value || 0);
}

function parseAmount(str) {
  const normalized = String(str).replace(/\./g,'').replace(',','.');
  const val = parseFloat(normalized);
  return isNaN(val) ? 0 : val;
}

const store = new Store();
