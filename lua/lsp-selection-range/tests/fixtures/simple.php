<?php

function max(int $left, int $right): bool
{
    if ($left < $right) {
        return $right;
    }

    return $left;
}
