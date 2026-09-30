<?php

declare(strict_types=1);

namespace DoubtQueue\Http;

use DoubtQueue\Exception\ValidationException;

class Request
{
    public function __construct(
        public readonly string $method,
        public readonly string $path,
        public readonly array $query = [],
        private readonly string $rawBody = ''
    ) {
    }

    public static function fromGlobals(): self
    {
        $path = (string) parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);

        return new self(
            strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET'),
            $path === '/' ? $path : rtrim($path, '/'),
            $_GET,
            (string) file_get_contents('php://input')
        );
    }

    public function body(): array
    {
        if (trim($this->rawBody) === '') {
            return [];
        }

        $data = json_decode($this->rawBody, true);

        if (!is_array($data)) {
            throw new ValidationException('Request body must be valid JSON');
        }

        return $data;
    }
}
