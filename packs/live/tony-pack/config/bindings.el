;; Place your bindings here.

(define-key global-map (kbd "C-+") 'text-scale-increase)
(define-key global-map (kbd "C--") 'text-scale-decrease)

;; make C-w to cut (even in paredit-mode)
(global-set-key (kbd "C-w") 'kill-region)
(define-key paredit-mode-map (kbd "C-w") 'kill-region)
(define-key paredit-mode-map (kbd "M-s") 'paredit-splice-sexp)
(define-key paredit-mode-map (kbd "M-S") 'paredit-split-sexp)

;; yank
(global-set-key (kbd "C-y") 'yank)

(global-set-key (kbd "C-v") (lambda () (interactive) (next-line 10)))
(global-set-key (kbd "M-v") (lambda () (interactive) (previous-line 10)))

;; some multi term tweaks
;;(require 'multi-term)
(global-set-key (kbd "C-c C-j") 'term-line-mode)

;; start or go to multi-term
(global-set-key (kbd "C-c C-z") 'multi-term-once)

;; To show/hide block of code
(require 'fold-dwim)
(global-set-key (kbd "C-c j") 'fold-dwim-toggle)
(global-set-key (kbd "C-c l") 'fold-dwim-hide-all)
(global-set-key (kbd "C-c ;") 'fold-dwim-show-all)

(global-set-key [remap find-tag] 'ido-find-tag)
(global-set-key (kbd "C-.") 'ido-find-file-in-tag-files)

(global-set-key (kbd "M-n") 'smart-symbol-go-forward)
(global-set-key (kbd "M-p") 'smart-symbol-go-backward)

(global-set-key (kbd "C-c C-i") 'after-jack-in)

(global-set-key (kbd "M-/") 'complete-symbol)

(global-set-key (kbd "C-c r") 'revert-buffer)

(define-key nrepl-interaction-mode-map (kbd "C-c C-e") '(lambda ()
                                                          (interactive)
                                                          (let ((curr (point)))
                                                            (end-of-defun)
                                                            (nrepl-eval-last-expression)
                                                            (goto-char curr))))
