emptyState = [zeros(19, 10); [1 0 1 0 1 0 1 0 1 0]];
c = state(emptyState);
p = pieces.S;

s = solver();

s.solve(c, p, p)


