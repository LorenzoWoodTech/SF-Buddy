# SF Buddy – HIG-Compliance & Simplification Checklist
*(Last updated: December 13, 2025 - Implementation started)*

---

## ‑-- GLOBAL PRINCIPLES
- Use Apple's native SwiftUI components wherever possible  
- Rely on system typography, spacing, colours, & SF Symbols  
- Every screen gets a single, clear responsibility  
- Empty content ⇒ `ContentUnavailableView`  
- All interactive items ≥ 44 × 44 pt (pointer‐aware hover size on macOS)  
- Provide haptic feedback on iOS for tap-to-select or confirmation actions  
- No hard-coded RGB; use `.foregroundStyle`, `.backgroundStyle`, or Asset colours  
- All compile warnings = **0** on every platform  

---

## 1 · MAIN NAVIGATION (NavigationSplitView)

✅ Convert `MainContentView` to single source of navigation truth  
✅ Bind `columnVisibility` so user can hide sidebar / inspector  
✅ Remove nested `NavigationStack` inside Split-View (`IconGridView` is enough)  
✅ Use `.navigationDestination(for: Icon.self)` to push inspector on iPhone  
✅ Replace sheet Add flow on macOS / iPad (regular width) with push form  
✅ Keep sheet for iPhone (compact) – uses `presentationDetents([.medium,.large])`  
✅ Add "Back/Close" toolbar item only where required  
✅ Ensure universal `searchable` drives same `@State searchText` in IconStore  

---

## 2 · SIDEBAR VIEW

✅ Section **Library**: All, Recent, SF Symbols, Custom (counts)  
✅ "Add Tag" ➜ toolbar button (`placement: .primaryAction`) not header  
✅ Replace colour dot with `labelStyle(.iconOnly)` using `circle.fill` tinted  
✅ Context menu: Rename…, Change Colour…, Delete (role: destructive)  
❏ Support drag-reorder for tags (`onMove`) – optional stretch goal  
✅ Use `HierarchicalListStyle` (macOS) / `.insetGrouped` (iOS)  

---

## 3 · ICON LIST VIEW  *(formerly IconGridView)*

✅ Rename to `IconListView` (List not Grid)  
✅ Row design  
 • Leading: 32 pt SF Symbol / custom asset, `.symbolRenderingMode(.hierarchical)`  
 • Title: semanticName – `.body`, weight medium  
 • Subtitle: baseSymbol (monospaced) + optional "• Custom" capsule  
✅ Row taps with `NavigationLink(value: icon)` (iPhone) / selection binding (mac)  
✅ Toolbar  
 • macOS: Add (cmd-N) & Publish… (shift-cmd-P)  
 • iOS: trailing plus only  
✅ Empty state: `ContentUnavailableView("No Icons", systemImage:"square.stack.3d.up.slash")`  

---

## 4 · ICON INSPECTOR

✅ Form with sections: Details · Tags (if any) · Variants (if any)  
✅ Use `Label` rows for tags (icon: "tag") with tag colour tint  
✅ Date fields formatted via shared `DateFormatter.short`  
✅ Edit… button → re-use IconForm in edit mode  
✅ mac toolbar: share/export code snippet (placeholder)  

---

## 5 · ICON FORM  *(Add / Edit)*

✅ Split into `IconFormCore` (re-usable) + wrappers Add / Edit  
✅ Validation  
 • semanticName: only lowercase, numbers, underscores – live red hint  
✅ Symbol picker button → sheet (compact) / popover (regular)  
❏ Tag selection: multi-select list with checkmarks  
✅ Preview section shows large symbol + metadata  
✅ Save disabled until form valid; provide haptic on success (iOS)  

---

## 6 · SYMBOL PICKER (SFSymbolBrowserView)

❏ Remove custom top toolbar – use segmented `Picker` for category  
✅ Grid: `LazyVGrid(columns:.adaptive(minimum:44))` –  hierarchy rendering  
✅ Category & search use SFSafeSymbols full list (`SFSymbol.allCases`)  
❏ AI search hidden behind Settings toggle; when active, results show AI badge  
✅ On selection: immediate dismiss + haptic (iOS)  
❏ macOS: keep "Select" primary button; iOS: none  

---

## 7 · PUBLISH SHEET

❏ Replace minimal text with branded empty state  
❏ Buttons: Learn More (open README link) · Notify Me (placeholder)  
❏ `presentationDetents([.medium,.large])` on iOS  

---

## 8 · SETTINGS (Scene based)

❏ Sections: Account · AI Options · Appearance · Advanced  
❏ API Key validation indicator (green check / yellow exclamation)  
❏ `Toggle("Show in Menu Bar")` macOS only  
❏ Symbol count Picker – menu style  
❏ Use `.formStyle(.grouped)` universal  

---

## 9 · ICON STORE

❏ Real‐time counts for smart groups (all / recent / sf / custom)  
❏ Combine‐publishers or `@MainActor` async fetch to avoid blocking UI  
❏ Provide `func duplicate(icon:)`, `func delete(…)` for context menus  

---

## 12 · EXECUTION ORDER

1️⃣ Fix build-blocking ContentUnavailableView syntax (done).  
2️⃣ Section 1 → fully functional navigation split view.  
3️⃣ Section 2 + 3 (sidebar + list) – new row components.  
4️⃣ Section 4 + 5 (inspector & form) – validation + edit flow.  
5️⃣ Section 6 (symbol picker simplification).  
6️⃣ Section 7 + 8 (publish sheet & settings).  
7️⃣ Section 9 + 10 polish & full accessibility audit.  
8️⃣ Snapshot / UI tests across Test Grid.  

All changes in feature branches; merge when compile-clean & checklist ticked.
