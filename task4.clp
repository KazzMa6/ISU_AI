; ==========================================================
; Экспертная система: Диагностика неисправностей ПК/Ноутбука
; Основано на главе 5 и 11 книги П. Джексона.
; Используется стратегия эвристической классификации.
; ==========================================================

; ==========================================================
; ШАБЛОНЫ (Структуры данных)
; ==========================================================
(deftemplate symptom
   (slot name (type SYMBOL))
   (slot value (type SYMBOL))
   (slot cf (type FLOAT) (default 1.0)) ; Коэффициент уверенности
)

; Шаблон для фиксации диагноза
(deftemplate diagnosis
   (slot problem (type STRING))
   (slot action (type STRING))
   (slot cf (type FLOAT))
)

; Шаблон для вопросов пользователю (для организации диалога)
(deftemplate question
   (slot id (type INTEGER))
   (slot text (type STRING))
   (slot symptom-name (type SYMBOL))
   (slot default (type SYMBOL) (default unknown))
)

; ==========================================================
; ФАКТЫ (Вопросы пользователю)
; Описываем сценарий диалога. Это аналог таблицы знаний из MYCIN.
; ==========================================================
(deffacts user-questions
   (question (id 1) (symptom-name power) (text "Включается ли компьютер при нажатии кнопки питания? (yes/no)"))
   (question (id 2) (symptom-name display) (text "Появляется ли изображение на мониторе/экране? (yes/no)"))
   (question (id 3) (symptom-name os) (text "Загружается ли операционная система (Windows)? (yes/no)"))
   (question (id 4) (symptom-name beep) (text "Издает ли компьютер звуковые сигналы (бип) при включении? (yes/no)"))
   (question (id 5) (symptom-name speed) (text "Работает ли компьютер медленно или зависает? (yes/no)"))
   (question (id 6) (symptom-name fans) (text "Слышен ли шум кулеров (вентиляторов)? (yes/no)"))
)

; ==========================================================
; ПРАВИЛА (База знаний)
; Правила построены по принципу "Если... То... с уверенностью CF".
; ==========================================================

; 1. ПРАВИЛО ДИАЛОГА: Задавать вопросы, если симптом неизвестен
(defrule ask-question
   ?q <- (question (id ?id) (text ?text) (symptom-name ?name))
   (not (symptom (name ?name)))
   =>
   (printout t crlf ?text crlf ">>> ")
   (bind ?answer (read))
   (assert (symptom (name ?name) (value ?answer) (cf 1.0)))
)

; 2. ДИАГНОСТИЧЕСКИЕ ПРАВИЛА (Эвристическая классификация)

; Правило 1: Нет питания
(defrule diagnose-no-power
   (symptom (name power) (value no))
   =>
   (assert (diagnosis (problem "Компьютер не включается") 
                      (action "Проверьте подключение к сети, блок питания или аккумулятор.") 
                      (cf 0.9)))
)

; Правило 2: Нет изображения
(defrule diagnose-no-display
   (symptom (name power) (value yes))
   (symptom (name display) (value no))
   =>
   (assert (diagnosis (problem "Нет изображения на экране") 
                      (action "Проверьте кабель монитора (HDMI/VGA) или попробуйте перезагрузить видеодрайвер.") 
                      (cf 0.85)))
)

; Правило 3: Проблемы с ОС
(defrule diagnose-os
   (symptom (name power) (value yes))
   (symptom (name display) (value yes))
   (symptom (name os) (value no))
   =>
   (assert (diagnosis (problem "Операционная система не загружается") 
                      (action "Попробуйте войти в безопасный режим (F8) или использовать восстановление системы.") 
                      (cf 0.9)))
)

; Правило 4: Тормозит
(defrule diagnose-slow
   (symptom (name power) (value yes))
   (symptom (name display) (value yes))
   (symptom (name os) (value yes))
   (symptom (name speed) (value yes))
   =>
   (assert (diagnosis (problem "Компьютер тормозит") 
                      (action "Проверьте загрузку ЦП в диспетчере задач, очистите диск, проверьте на вирусы.") 
                      (cf 0.75)))
)

; Правило 5: Неисправность ОЗУ (сигналы бип)
(defrule diagnose-ram
   (symptom (name power) (value no))
   (symptom (name beep) (value yes))
   =>
   (assert (diagnosis (problem "Неисправность оперативной памяти (RAM) или видеокарты") 
                      (action "Извлеките и переустановите планки ОЗУ. Если не поможет - замените.") 
                      (cf 0.7)))
)

; Правило 6: Перегрев
(defrule diagnose-overheat
   (symptom (name power) (value yes))
   (symptom (name fans) (value no))
   =>
   (assert (diagnosis (problem "Перегрев процессора (шум вентилятора отсутствует)") 
                      (action "Очистите систему охлаждения от пыли и замените термопасту.") 
                      (cf 0.8)))
)

; ==========================================================
; ПРАВИЛО ЗАВЕРШЕНИЯ: Вывод результата
; ==========================================================
(defrule print-diagnosis
   (diagnosis (problem ?p) (action ?a) (cf ?cf))
   (not (diagnosis (cf ?other&:(> ?other ?cf)))) ; Находим диагноз с самой высокой уверенностью
   =>
   (printout t crlf "========================================" crlf)
   (printout t "ДИАГНОЗ УСТАНОВЛЕН (Уверенность: " (* ?cf 100) "%):" crlf)
   (printout t ?p crlf)
   (printout t "РЕКОМЕНДАЦИЯ: " ?a crlf)
   (printout t "========================================" crlf)
   (halt)
)

; ==========================================================
; ЗАПУСК
; ==========================================================
; (reset) - инициализирует факты вопросов
; (run) - запускает правила