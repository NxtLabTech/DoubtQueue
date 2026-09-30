<?php

declare(strict_types=1);

namespace DoubtQueue;

use PDO;

class Database
{
    public static function connect(): PDO
    {
        if (Config::get('DB_DRIVER', 'sqlite') === 'mysql') {
            return self::connectMysql();
        }

        return self::connectSqlite();
    }

    public static function memory(): PDO
    {
        return self::sqlite('sqlite::memory:');
    }

    private static function connectSqlite(): PDO
    {
        $path = Config::get('DB_PATH', 'data/doubtqueue.sqlite');

        if (!self::isAbsolute($path)) {
            $path = dirname(__DIR__) . '/' . $path;
        }

        return self::sqlite('sqlite:' . $path);
    }

    private static function connectMysql(): PDO
    {
        $dsn = sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
            Config::get('DB_HOST', '127.0.0.1'),
            Config::get('DB_PORT', '3306'),
            Config::get('DB_NAME', 'doubtqueue')
        );

        return self::configure(new PDO(
            $dsn,
            Config::get('DB_USERNAME', 'root'),
            Config::get('DB_PASSWORD', 'root')
        ));
    }

    private static function sqlite(string $dsn): PDO
    {
        $pdo = self::configure(new PDO($dsn));
        $pdo->exec('PRAGMA foreign_keys = ON');

        return $pdo;
    }

    private static function configure(PDO $pdo): PDO
    {
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

        return $pdo;
    }

    private static function isAbsolute(string $path): bool
    {
        return str_starts_with($path, '/') || preg_match('/^[A-Za-z]:[\\\\\/]/', $path) === 1;
    }
}
