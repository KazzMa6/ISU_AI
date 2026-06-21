double_list([], []).
double_list([H|T], [H,H|R]) :- double_list(T, R).

% Тестовый предикат для демонстрации
test :-
    double_list([a,b,c], X),
    write('Результат: '), write(X), nl.
