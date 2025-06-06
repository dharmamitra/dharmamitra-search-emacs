;;; dharmamitra-search.el --- Query Dharmamitra API from a marked region -*- lexical-binding:t; -*-

;; Author: Sebastian Nehrdich <nehrdich@berkeley.edu>
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools, convenience, text, sanskrit, tibetan, chinese, pali
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; Mark a region, hit your key binding, and the text is sent to
;; https://dharmamitra.org/api-search/primary/ (`search_input`).
;;
;; The *Dharmamitra Results* buffer is read-only (special-mode), shows
;; clickable titles and nicely formatted “text” fields; subsequent searches
;; simply refresh that buffer.

;;; Code:

(require 'json)
(require 'url)
(require 'button)
(require 'cl-lib)
(require 'subr-x)

;;;; Faces --------------------------------------------------------------------

(defgroup dharmamitra-search nil
  "Query the Dharmamitra semantic-search API."
  :group 'external :prefix "dharmamitra-search-")

(defcustom dharmamitra-search-endpoint
  "https://dharmamitra.org/api-search/primary/"
  "REST endpoint for Dharmamitra semantic search."
  :type 'string :group 'dharmamitra-search)

(defface dharmamitra-results-header
  '((t :weight bold :height 1.4))  "Face for the big header line."
  :group 'dharmamitra-search)

(defface dharmamitra-results-title
  '((t :weight bold :height 1.15)) "Face for each result title."
  :group 'dharmamitra-search)

(defface dharmamitra-results-meta
  '((t :inherit shadow))           "Face for light metadata."
  :group 'dharmamitra-search)

(defface dharmamitra-results-rule
  '((t :inherit shadow))           "Face for horizontal rules."
  :group 'dharmamitra-search)

;;;; Helper mode --------------------------------------------------------------

(define-derived-mode dharmamitra-results-mode special-mode "Mitra-Results"
  "Major mode for *Dharmamitra Results* buffers."
  (setq-local line-spacing 0.2)
  (visual-line-mode 1))

;;;; Utility helpers ----------------------------------------------------------

(defun dharmamitra--button (label url)
  "Insert LABEL as a clickable text button that opens URL."
  (insert-text-button label
                      'action (lambda (_b) (browse-url url))
                      'follow-link t
                      'help-echo url
                      'face '(dharmamitra-results-title link)))

(defun dharmamitra--hr ()
  (insert (propertize (make-string (min 80 (window-width)) ?─)
                      'face 'dharmamitra-results-rule)
          "\n\n"))

(defun dharmamitra--http-ok-p ()
  "Return non-nil if current `url-retrieve` buffer is a 200 JSON reply."
  (goto-char (point-min))
  (re-search-forward "^HTTP/[0-9.]+ \\([0-9]+\\)" nil t)
  (let ((code (string-to-number (match-string 1))))
    (and (= code 200)
         (re-search-forward "^Content-Type: *application/json" nil t))))

;;;; Main command -------------------------------------------------------------

;;;###autoload
(defun dharmamitra-search-region (beg end)
  "POST the region (BEG..END) to the Dharmamitra semantic-search API."
  (interactive "r")
  (unless (use-region-p) (user-error "No active region"))
  (let* ((query (buffer-substring-no-properties beg end))
         (payload (encode-coding-string
                   (json-encode
                    `(("search_input" . ,query)
                      ("input_encoding" . "auto")
                      ("search_type" . "semantic")
                      ("filter_source_language" . "all")
                      ("filter_target_language" . "all")
                      ("source_filters"
                       . (("include_files" . [])
                          ("include_categories" . [])
                          ("include_collections" . [])))
                      ("do_ranking" . t)))
                   'utf-8))
         (url-request-method "POST")
         (url-request-extra-headers
          '(("Accept"       . "application/json")
            ("Content-Type" . "application/json; charset=utf-8")))
         (url-request-data payload)
         (resp (url-retrieve-synchronously dharmamitra-search-endpoint t)))
    (unless resp (user-error "No response from server"))
    (with-current-buffer resp
      (if (not (dharmamitra--http-ok-p))
          (progn
            (message "Server returned non-JSON or non-200; see *Dharmamitra HTTP*")
            (rename-buffer "*Dharmamitra HTTP*" t)
            (pop-to-buffer (current-buffer)))
        ;; strip headers
        (re-search-forward "\n\n" nil t)
        (delete-region (point-min) (point))
        (condition-case err
            (let* ((json-object-type 'alist)
                   (json-array-type  'vector)
                   (json-key-type    'symbol)
                   (data (json-parse-buffer :object-type 'alist)))
              (dharmamitra--show-results query (alist-get 'results data)))
          (json-parse-error
           (message "JSON parse error: %s" (error-message-string err))
           (pop-to-buffer (current-buffer)))))
      (kill-buffer resp))))

(defun dharmamitra--show-results (query results)
  "Pretty-print RESULTS into the *Dharmamitra Results* buffer."
  (let ((buf (get-buffer-create "*Dharmamitra Results*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (dharmamitra-results-mode)
        (insert (propertize "Dharmamitra Search Results\n"
                            'face 'dharmamitra-results-header))
        (insert (propertize (format "Query: %s\n\n" query) 'face 'italic))
        (if (zerop (length results))
            (insert "⚠️  No results.\n")
          (mapc
           (lambda (r)
             (let ((title   (alist-get 'title     r))
                   (seg     (alist-get 'segmentnr r))
                   (link    (alist-get 'src_link  r))
                   (text    (alist-get 'text      r)))
               (dharmamitra--button title (or link ""))
               (when seg
                 (insert (propertize (format "  (%s)" seg)
                                     'face 'dharmamitra-results-meta)))
               (insert "\n")
               (when text
                 (let ((start (point)))
                   (insert (replace-regexp-in-string "🔽" "\n" text t t) "\n\n")
                   (fill-region start (point))))
               (dharmamitra--hr)))
           results)))
      (goto-char (point-min)))
    (pop-to-buffer buf)))

(provide 'dharmamitra-search)
;;; dharmamitra-search.el ends here
