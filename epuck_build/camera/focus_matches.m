function ok = focus_matches(current, reference)
ok = current.mode == reference.mode && isequaln(current.value,reference.value);
end
