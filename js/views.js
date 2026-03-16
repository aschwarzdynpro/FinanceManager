'use strict';

// ─── Dashboard View ──────────────────────────────────────────────────────────

function renderDashboard(year) {
  const entries  = store.entriesForYear(year);
  const totalIncome  = store.annualIncome(year);
  const totalPlanned = entries.reduce((s,e) => s + e.allocations.reduce((ss,a) => ss + (a.planned||0), 0), 0);
  const totalActual  = entries.reduce((s,e) => s + e.allocations.reduce((ss,a) => ss + (a.actual||0), 0), 0);

  return `
    <div class="view-header">
      <h1>Übersicht ${year}</h1>
    </div>

    <div class="summary-banner">
      <div class="summary-item">
        <span class="summary-label">Einnahmen</span>
        <span class="summary-value">${fmt(totalIncome)}</span>
      </div>
      <div class="summary-divider"></div>
      <div class="summary-item">
        <span class="summary-label">Geplant</span>
        <span class="summary-value">${fmt(totalPlanned)}</span>
      </div>
      <div class="summary-divider"></div>
      <div class="summary-item">
        <span class="summary-label">Tatsächlich</span>
        <span class="summary-value">${fmt(totalActual)}</span>
      </div>
    </div>

    <div class="card-grid">
      ${store.getCategories().map(cat => renderCategoryCard(year, cat)).join('')}
    </div>

    <div class="card">
      <h2 class="section-title">Monatliche Einnahmen</h2>
      ${renderIncomeChart(year, entries)}
    </div>
  `;
}

function renderCategoryCard(year, cat) {
  const actual  = store.annualTotal(year, cat.id, 'actual');
  const planned = store.annualTotal(year, cat.id, 'planned');
  const goal    = store.getGoal(year, cat.id);
  const progress = goal > 0 ? Math.min(actual / goal, 1) : 0;
  const pct      = Math.round(progress * 100);

  return `
    <div class="card category-card">
      <div class="cat-card-header">
        <span class="cat-icon">${cat.icon}</span>
        <span class="cat-label">${cat.label}</span>
        ${goal > 0 ? `<span class="cat-pct" style="color:${cat.color}">${pct}%</span>` : ''}
      </div>

      ${goal > 0 ? `
        <div class="progress-track">
          <div class="progress-fill" style="width:${pct}%;background:${cat.color}"></div>
        </div>
        <div class="cat-amounts">
          <span style="color:${cat.color};font-weight:600">${fmt(actual)}</span>
          <span class="muted">/ ${fmt(goal)}</span>
        </div>
        <div class="cat-sub">
          <span class="muted small">Geplant: ${fmt(planned)}</span>
          <span class="muted small">Verbleibend: ${fmt(Math.max(goal - actual, 0))}</span>
        </div>
      ` : `
        <div class="cat-amounts">
          <span style="color:${cat.color};font-weight:600">${fmt(actual)}</span>
        </div>
        <div class="cat-sub">
          <span class="muted small">Geplant: ${fmt(planned)}</span>
          <span class="muted small">Kein Jahresziel</span>
        </div>
      `}
    </div>
  `;
}

function renderIncomeChart(year, entries) {
  if (!entries.length) return '<p class="muted">Noch keine Daten.</p>';
  const max = Math.max(...entries.map(e => e.income), 1);
  return `
    <div class="bar-chart">
      ${entries.map(e => {
        const pct = max > 0 ? (e.income / max * 100) : 0;
        return `
          <div class="bar-row">
            <span class="bar-label">${MONTH_NAMES[e.month-1].slice(0,3)}</span>
            <div class="bar-track">
              <div class="bar-fill" style="width:${pct}%"></div>
            </div>
            <span class="bar-value">${fmt(e.income)}</span>
          </div>`;
      }).join('')}
    </div>`;
}

// ─── Monthly Detail View ──────────────────────────────────────────────────────

function renderMonthly(year, month) {
  const entry = store.getEntry(year, month) || store._newEntry(year, month);
  const remaining = (entry.income||0) - entry.allocations.reduce((s,a)=>s+(a.planned||0),0);
  const remClass  = remaining >= 0 ? 'positive' : 'negative';

  return `
    <div class="view-header">
      <h1>${MONTH_NAMES[month-1]} ${year}</h1>
    </div>

    <div class="card">
      <h2 class="section-title">Einnahmen</h2>
      <div class="income-row">
        <span class="income-icon">💶</span>
        <input class="income-input" type="text" inputmode="decimal"
               placeholder="0,00" value="${entry.income ? fmtInput(entry.income) : ''}"
               data-field="income" />
        <span class="income-currency">€</span>
      </div>
    </div>

    <div class="allocations-grid">
      ${store.getCategories().map(cat => {
        const alloc = entry.allocations.find(a => a.categoryId === cat.id)
          || { categoryId: cat.id, planned: 0, actual: 0 };
        const goal       = store.getGoal(year, cat.id);
        const annActual  = store.annualTotal(year, cat.id, 'actual');
        const annPct     = goal > 0 ? Math.min(annActual / goal * 100, 100) : 0;
        const diff       = (alloc.planned||0) - (alloc.actual||0);

        return `
          <div class="card alloc-card" data-cat="${cat.id}">
            <div class="alloc-header">
              <span class="cat-icon">${cat.icon}</span>
              <div class="alloc-title">
                <span class="cat-label">${cat.label}</span>
                ${goal > 0 ? `<span class="muted small">Jahresfortschritt: ${fmt(annActual)} / ${fmt(goal)}</span>` : ''}
              </div>
              <span class="alloc-planned" style="color:${cat.color}">${fmt(alloc.planned)}</span>
            </div>

            ${goal > 0 ? `
              <div class="progress-track" style="margin:8px 0">
                <div class="progress-fill" style="width:${annPct.toFixed(1)}%;background:${cat.color}"></div>
              </div>` : ''}

            <div class="alloc-fields">
              <label class="field-group">
                <span class="field-label">Geplant (€)</span>
                <input type="text" inputmode="decimal" placeholder="0,00"
                       value="${alloc.planned ? fmtInput(alloc.planned) : ''}"
                       data-cat="${cat.id}" data-field="planned" class="alloc-input" />
              </label>
              <label class="field-group">
                <span class="field-label">Tatsächlich (€)</span>
                <input type="text" inputmode="decimal" placeholder="0,00"
                       value="${alloc.actual ? fmtInput(alloc.actual) : ''}"
                       data-cat="${cat.id}" data-field="actual" class="alloc-input" />
              </label>
            </div>

            ${alloc.actual > 0 ? `
              <div class="alloc-diff ${diff >= 0 ? 'positive' : 'negative'}">
                Differenz: ${fmt(diff)}
              </div>` : ''}
          </div>`;
      }).join('')}
    </div>

    <div class="card summary-footer ${remClass}">
      <div class="summary-item">
        <span class="summary-label">Einnahmen</span>
        <span class="summary-value">${fmt(entry.income)}</span>
      </div>
      <div class="summary-divider"></div>
      <div class="summary-item">
        <span class="summary-label">Geplant</span>
        <span class="summary-value">${fmt(entry.allocations.reduce((s,a)=>s+(a.planned||0),0))}</span>
      </div>
      <div class="summary-divider"></div>
      <div class="summary-item">
        <span class="summary-label">Verbleibend</span>
        <span class="summary-value">${fmt(remaining)}</span>
      </div>
    </div>
  `;
}

// ─── Annual Goals View ────────────────────────────────────────────────────────

function renderGoals(year) {
  return `
    <div class="view-header">
      <h1>Jahresziele ${year}</h1>
    </div>

    <div class="card goals-header-card">
      <span class="goals-icon">🎯</span>
      <p>Lege deine finanziellen Ziele für ${year} fest und verfolge deinen Fortschritt.</p>
    </div>

    <div class="card-grid">
      ${store.getCategories().map(cat => renderGoalCard(year, cat)).join('')}
    </div>

    <div class="card">
      <h2 class="section-title">Jahresüberblick ${year}</h2>
      <div class="goals-table">
        ${store.getCategories().map(cat => {
          const goal    = store.getGoal(year, cat.id);
          const actual  = store.annualTotal(year, cat.id, 'actual');
          const planned = store.annualTotal(year, cat.id, 'planned');
          const pct     = goal > 0 ? Math.min(actual / goal * 100, 100) : 0;
          return `
            <div class="goals-row">
              <div class="goals-row-left">
                <span class="cat-icon">${cat.icon}</span>
                <span class="cat-label">${cat.label}</span>
              </div>
              <div class="goals-row-right">
                <span style="color:${cat.color};font-weight:600">${fmt(actual)}</span>
                ${goal > 0 ? `<span class="muted small">Ziel: ${fmt(goal)}</span>` : ''}
              </div>
            </div>
            ${goal > 0 ? `
              <div class="progress-track" style="margin:-4px 0 12px 36px">
                <div class="progress-fill" style="width:${pct.toFixed(1)}%;background:${cat.color}"></div>
              </div>` : `
              <div class="goals-sub muted small" style="margin:-4px 0 12px 36px">Geplant: ${fmt(planned)}</div>`}
          `;
        }).join('')}
      </div>
    </div>
  `;
}

function renderGoalCard(year, cat) {
  const goal    = store.getGoal(year, cat.id);
  const actual  = store.annualTotal(year, cat.id, 'actual');
  const progress = goal > 0 ? Math.min(actual / goal, 1) : 0;
  const pct      = Math.round(progress * 100);

  return `
    <div class="card goal-card">
      <div class="cat-card-header">
        <span class="cat-icon">${cat.icon}</span>
        <span class="cat-label">${cat.label}</span>
      </div>
      <label class="field-group">
        <span class="field-label">Jahresziel (€)</span>
        <input type="text" inputmode="decimal" placeholder="0,00"
               value="${goal ? fmtInput(goal) : ''}"
               data-cat="${cat.id}" data-year="${year}" class="goal-input"
               style="border-color:${cat.color}40" />
      </label>
      ${goal > 0 ? `
        <div class="progress-track" style="margin-top:10px">
          <div class="progress-fill" style="width:${pct}%;background:${cat.color}"></div>
        </div>
        <div class="cat-amounts">
          <span style="color:${cat.color}">${fmt(actual)}</span>
          <span class="muted small">${pct}%</span>
        </div>
      ` : `<p class="muted small" style="margin-top:8px">Kein Ziel gesetzt</p>`}
    </div>
  `;
}

// ─── Templates View ──────────────────────────────────────────────────────────

function renderTemplates() {
  const templates = store.getTemplates();
  const totalTemplate = store.getCategories().reduce((s, c) => s + (templates[c.id] || 0), 0);

  return `
    <div class="view-header">
      <h1>Vorlagen</h1>
    </div>

    <div class="card templates-info-card">
      <span class="templates-icon">📋</span>
      <div>
        <p>Definiere Standardbeträge pro Kategorie.</p>
        <p class="muted small">Diese Werte werden automatisch als <strong>Geplant</strong> eingetragen, wenn du einen neuen Monat hinzufügst.</p>
      </div>
    </div>

    <div class="card-grid">
      ${store.getCategories().map(cat => `
        <div class="card template-card">
          <div class="cat-card-header">
            <span class="cat-icon">${cat.icon}</span>
            <span class="cat-label">${cat.label}</span>
          </div>
          <label class="field-group" style="margin-top:10px">
            <span class="field-label">Monatlicher Standardbetrag (€)</span>
            <input type="text" inputmode="decimal" placeholder="0,00"
                   value="${templates[cat.id] ? fmtInput(templates[cat.id]) : ''}"
                   data-cat="${cat.id}" class="template-input alloc-input"
                   style="border-color:${cat.color}40" />
          </label>
          ${templates[cat.id] ? `
            <p class="muted small" style="margin-top:6px">
              = ${fmt(templates[cat.id])} / Monat
            </p>` : `
            <p class="muted small" style="margin-top:6px; font-style:italic">
              Kein Standardbetrag gesetzt
            </p>`}
        </div>
      `).join('')}
    </div>

    ${totalTemplate > 0 ? `
      <div class="card templates-summary">
        <span class="muted small">Gesamt Standardbudget pro Monat</span>
        <span class="templates-total">${fmt(totalTemplate)}</span>
      </div>
    ` : ''}
  `;
}

// ─── Category Settings View ───────────────────────────────────────────────────

const ICON_PALETTE = [
  '💰','💵','💳','📈','📉','🏦','🏠','🚗','✈️','🏖️',
  '🎓','💊','🛒','🍕','🎮','👕','🏋️','💍','🎁','📱',
  '💻','🔧','⛽','🚂','🏥','📚','🌱','🐾','🎵','🍷',
  '☕','🎯','🏆','🎨','🚀','💡','🔑','📷','🌍','🧳',
];

function renderCategorySettings() {
  const categories = store.getCategories();
  return `
    <div class="view-header">
      <h1>Kategorien</h1>
    </div>

    <div class="card cat-settings-info">
      <span class="templates-icon">⚙️</span>
      <div>
        <p>Verwalte deine Ausgabenkategorien.</p>
        <p class="muted small">Änderungen wirken sich auf neue Monate aus. Bestehende Daten bleiben erhalten.</p>
      </div>
    </div>

    <div class="cat-settings-list">
      ${categories.map(cat => renderCategoryRow(cat)).join('')}
    </div>

    <button class="btn btn-primary btn-add-cat" onclick="openAddCategoryModal()">
      + Neue Kategorie
    </button>
  `;
}

function renderCategoryRow(cat) {
  const inputId = `icon-preview-${cat.id}`;
  return `
    <div class="card cat-row" data-cat-id="${cat.id}">
      <button class="cat-icon-btn" onclick="openIconPicker('${cat.id}','${inputId}')"
              id="${inputId}" title="Icon ändern">
        ${cat.icon}
      </button>

      <input class="cat-label-input alloc-input" type="text"
             value="${escapeHtml(cat.label)}"
             placeholder="Name"
             data-cat-id="${cat.id}" />

      <label class="cat-color-wrap" title="Farbe wählen">
        <input type="color" class="cat-color-input"
               value="${cat.color}"
               data-cat-id="${cat.id}" />
        <span class="cat-color-swatch" style="background:${cat.color}"></span>
      </label>

      <button class="btn btn-save-cat" onclick="saveCategoryEdit('${cat.id}')"
              title="Speichern">✓</button>
      <button class="cat-delete-btn" onclick="deleteCategory('${cat.id}')"
              title="Löschen">🗑️</button>
    </div>
  `;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function escapeHtml(str) {
  return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function fmtInput(val) {
  return val ? val.toFixed(2).replace('.', ',') : '';
}
