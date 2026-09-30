<?php

declare(strict_types=1);

namespace DoubtQueue\Http;

class Response
{
    public function __construct(public readonly int $status, public readonly array $body)
    {
    }

    public static function error(int $status, string $message): self
    {
        return new self($status, ['status' => $status, 'message' => $message]);
    }

    public function send(): void
    {
        http_response_code($this->status);
        header('Content-Type: application/json');
        echo json_encode($this->body, JSON_UNESCAPED_SLASHES);
    }
}
