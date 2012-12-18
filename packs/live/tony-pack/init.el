;; User pack init file
;;
;; User this file to initiate the pack configuration.
;; See README for more information.

;; workaround for launching emacs from the stumpwm path
;; this will permit the starting of lein (which is in /home/tony/bin)
(setenv "PATH" (concat "/home/tony/bin:" (getenv "PATH")))

;; starter-kit snippets of code imported brutally after the default one (from emacs-live's init.el)

(require 'package)
(add-to-list 'package-archives
             '("marmalade" . "http://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)
(package-initialize)

(when (not package-archive-contents)
  (package-refresh-contents))

(defvar my-packages '(switch-window slime slime-repl ediff org flymake-shell graphviz-dot-mode fold-dwim htmlize edit-server puppet-mode haskell-mode)
  "A list of packages to ensure are installed at launch.")

(dolist (p my-packages)
  (when (not (package-installed-p p))
    (package-install p)))

;; common-lisp setup

(setq inferior-lisp-program "/usr/bin/clisp")
;; (add-to-list ’load-path "/home/tony/.emacs.d/elpa/slime-20100404.1/")
;; (require ’slime-autoloads)
;; (slime-setup)

;; some text/font/color tweaks

(setq-default fill-column 120)
(set-face-background 'default "black")

(set-language-environment "UTF-8")
(blink-cursor-mode 1)

;; puppet-mode for the .pp file

(add-to-list 'auto-mode-alist '("\.pp$" . puppet-mode))

;; add paredit mode to different modes

(dolist (hook '(lisp-mode
                inferior-lisp-mode-hook
                slime-repl-mode-hook
                nrepl-mode-hook))
  (add-hook hook (lambda () (paredit-mode +1))))

;; slime repl setup

; add color into the repl via clojure-jack-in
(add-hook 'slime-repl-mode-hook
         (defun clojure-mode-slime-font-lock ()
           (let (font-lock-mode)
             (clojure-mode-font-lock-setup))))

(setq slime-net-coding-system 'utf-8-unix)

;; some personal functions that extends the one loaded from user.el

(defun exists-session-or-spawn-it (session-name session-command)
  "Given a session-name, check the existence of such a session. If it doesn't exist, spawn the session via the command session-command"
  (let ((proc (get-buffer-process session-name)))
    (unless (and proc (eq (process-status proc) 'run))
      (funcall session-command))))

(defun switch-to-buffer-or-nothing (process-name buffer-name)
  "Given a process name, switch to the corresponding buffer-name if the process is running or does nothing."
  (unless (string= (buffer-name) buffer-name)
    (let ((proc (get-buffer-process process-name)))
      (if (and proc (eq (process-status proc) 'run))
          (switch-to-buffer-other-window buffer-name)))))

;; examples
;; (switch-to-buffer-or-nothing "*swank*" "*slime-repl nil*")    ;; clojure-jack-in
;; (switch-to-buffer-or-nothing "*terminal<1>*" "*terminal<1>*") ;; multi-term

(defun multi-term-once ()
  "Check the existence of a terminal with multi-term.
If it doesn't exist, launch it. Then go to this buffer in another buffer."
  (interactive)
  (unless (exists-session-or-spawn-it "*terminal<1>*" 'multi-term)
    (switch-to-buffer-or-nothing "*terminal<1>*" "*terminal<1>*")))

(defun jack-in-once ()
  "Check the existence of a repl session (nrepl or slime). If it doesn't exist, launch it."
  (interactive)
  (exists-session-or-spawn-it "*nrepl-server*" (lambda () (nrepl-jack-in nil))))

;;   (exists-session-or-spawn-it "*swank*" 'clojure-jack-in)

;; other bindings that uses personal functions

(add-hook 'clojure-mode-hook 'jack-in-once)

;; Some org-mode setup


;; org-mode for the .org file

(add-to-list 'auto-mode-alist '("\.org$" . org-mode))

(column-number-mode)

(setq org-directory "~/org")

(setq org-startup-indented t)

(setq org-log-done 'time)

(setq org-default-notes-file (concat org-directory "/notes.org"))

(define-key global-map "\C-cc" 'org-capture)

(setq org-tag-alist '(("howTo" . ?h)
                      ("tech" . ?t)
                      ("emacs" . ?e)
                      ("orgMode" . ?o)
                      ("faq" . ?f)
                      ("firefox")
                      ("conkeror")
                      ("linux")))

(setq org-todo-keywords
   '((sequence "TODO" "IN-PROGRESS" "PENDING" "|"  "DONE" "FAIL" "DELEGATED" "CANCELLED")))

;; C-x C-l to lower case ; C-x C-u to upper case

(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)

;; Find file in project

(eval-after-load 'find-file-in-project
  '(progn
     ;; add 'entreprise' files patterns (cough!)
     (setq ffip-patterns
           (append ffip-patterns
                   '("*.cs*""*.htm*" "*.java" "*.js*" "*.php"
                     "*.properties" "*.sql" "*.xml" "*.clj*")))
     ;; increase the max number of files, otherwise some files will be
     ;; 'unfindable' on big projects
     (setq ffip-limit 8192)))

;; etags

(require 'etags)

(defun ido-find-tag ()
  "Find a tag using ido"
  (interactive)
  (tags-completion-table)
  (let (tag-names)
    (mapc (lambda (x)
            (unless (integerp x)
              (push (prin1-to-string x t) tag-names)))
          tags-completion-table)
    (find-tag (ido-completing-read "Tag: " tag-names))))

(defun ido-find-file-in-tag-files ()
  (interactive)
  (save-excursion
    (let ((enable-recursive-minibuffers t))
      (visit-tags-table-buffer))
    (find-file
     (expand-file-name
      (ido-completing-read
       "Project file: " (tags-table-files) nil t)))))

;; to improve the movement in files

(defvar smart-use-extended-syntax nil
  "If t the smart symbol functionality will consider extended
syntax in finding matches, if such matches exist.")

(defvar smart-last-symbol-name ""
  "Contains the current symbol name.

This is only refreshed when `last-command' does not contain
either `smart-symbol-go-forward' or `smart-symbol-go-backward'")

(make-local-variable 'smart-use-extended-syntax)

(defvar smart-symbol-old-pt nil
  "Contains the location of the old point")

(defun smart-symbol-goto (name direction)
  "Jumps to the next NAME in DIRECTION in the current buffer.

DIRECTION must be either `forward' or `backward'; no other option
is valid."

  ;; if `last-command' did not contain
  ;; `smart-symbol-go-forward/backward' then we assume it's a
  ;; brand-new command and we re-set the search term.
  (unless (memq last-command '(smart-symbol-go-forward
                               smart-symbol-go-backward))
    (setq smart-last-symbol-name name))
  (setq smart-symbol-old-pt (point))
  (message (format "%s scan for symbol \"%s\""
                   (capitalize (symbol-name direction))
                   smart-last-symbol-name))
  (unless (catch 'done
            (while (funcall (cond
                             ((eq direction 'forward) ; forward
                              'search-forward)
                             ((eq direction 'backward) ; backward
                              'search-backward)
                             (t (error "Invalid direction"))) ; all others
                            smart-last-symbol-name nil t)
              (unless (memq (syntax-ppss-context
                             (syntax-ppss (point))) '(string comment))
                (throw 'done t))))
    (goto-char smart-symbol-old-pt)))

(defun smart-symbol-go-forward ()
  "Jumps forward to the next symbol at point"
  (interactive)
  (smart-symbol-goto (smart-symbol-at-pt 'end) 'forward))

(defun smart-symbol-go-backward ()
  "Jumps backward to the previous symbol at point"
  (interactive)
  (smart-symbol-goto (smart-symbol-at-pt 'beginning) 'backward))

(defun smart-symbol-at-pt (&optional dir)
  "Returns the symbol at point and moves point to DIR (either `beginning' or `end') of the symbol.

If `smart-use-extended-syntax' is t then that symbol is returned
instead."
  (with-syntax-table (make-syntax-table)
    (if smart-use-extended-syntax
        (modify-syntax-entry ?. "w"))
    (modify-syntax-entry ?_ "w")
    (modify-syntax-entry ?- "w")
    ;; grab the word and return it
    (let ((word (thing-at-point 'word))
          (bounds (bounds-of-thing-at-point 'word)))
      (if word
          (progn
            (cond
             ((eq dir 'beginning) (goto-char (car bounds)))
             ((eq dir 'end) (goto-char (cdr bounds)))
             (t (error "Invalid direction")))
            word)
        (error "No symbol found")))))

;; To dynamically extend emacs via macros

(defun save-macro (name)
  "save a macro. Take a name as argument and save the last
     defined macro under this name at the end of your .emacs"
     (interactive "SName of the macro :")  ; ask for the name of the macro
     (kmacro-name-last-macro name)         ; use this name for the macro
     (find-file user-init-file)            ; open ~/.emacs or other user init file
     (goto-char (point-max))               ; go to the end of the .emacs
     (newline)                             ; insert a newline
     (insert-kbd-macro name)               ; copy the macro
     (newline)                             ; insert a newline
     (switch-to-buffer nil))               ; return to the initial buffer

;; Macro generated by emacs

(fset 'after-jack-in
      (lambda (&optional arg)
        "A macro to dispose emacs buffer as i'm used to after the clojure-jack-in is started."
        (interactive "p")
        (kmacro-exec-ring-item (quote ([24 48 24 50 24 111 134217848 109 117 108 116 105 return 108 101 105 110 32 109 105 100 106 101 32 45 45 108 97 122 121 116 101 115 116 return 24 51 24 111 24 98 110 114 101 112 108 return 24 98 42 110 114 101 112 108 42 return 24 111] 0 "%d")) arg)))

;;;;;;;;;;;;;;;;;;;;; haskell

(add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)

;; hslint on the command line only likes this indentation mode;
;; alternatives commented out below.
(add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)
;;(add-hook 'haskell-mode-hook 'turn-on-haskell-indent)
;;(add-hook 'haskell-mode-hook 'turn-on-haskell-simple-indent)

;; Ignore compiled Haskell files in filename completions
(add-to-list 'completion-ignored-extensions ".hi")

;;;;;;;;;;;;;;;;;;;;; load the general bindings

;; Load bindings config
(live-load-config-file "bindings.el")

;; edit-server
(if (and (daemonp) (locate-library "edit-server"))
     (progn
       (require 'edit-server)
       (setq edit-server-new-frame nil)
       (edit-server-start)))
