<?php

declare(strict_types=1);

namespace DoubtQueue;

class Config
{
    public static function get(string $name, string $default): string
    {
        $value = getenv($name);

        return $value === false || $value === '' ? $default : $value;
    }
}
