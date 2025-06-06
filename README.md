# Dharmamitra Search  

> **Comfortable semantic search of the entire  
> [dharmamitra.org](https://dharmamitra.org) corpus — right from Emacs.**

`dharmamitra-search.el` lets you highlight _any_ text in any buffer, hit a
single key, and instantly browse cross-lingual search results (Sanskrit · Tibetan · 
Chinese · Pāli) returned by Dharmamitra's semantic-search API.

<table><tr><td>

![Dharmamitra Search Demo](screenshot.png)

</td></tr></table>

*(screencast: mark text → `C-c C-d` → clickable results window)*

---

## ✨ Features

| ✔ | Description |
|----|-------------|
| **Zero setup** | Pure-Elisp, no external deps, needs only vanilla Emacs 27+. |
| **Rich results** | Clickable titles open the source page; reference database is not yet up and running, but will come soon. |
| **Non-destructive** | Results appear in their own read-only buffer (derived from `special-mode`). |
| **Customisable** | Endpoint, faces, key binding - all via Emacs' customization UI. |
| **MIT-licensed** | Do whatever you like with it. Contributions welcome! |

---

## ⏳ Installation

<details>
<summary><tt>straight.el</tt> / <tt>use-package</tt></summary>

```elisp
(use-package dharmamitra-search
  :straight (dharmamitra-search
             :type git
             :host github
             :repo "your-github-name/dharmamitra-search")
  :bind ("C-c C-d" . dharmamitra-search-region))

```
</details>
