<?php

declare(strict_types=1);

namespace DoubtQueue\Service;

use DoubtQueue\Exception\NotFoundException;
use DoubtQueue\Exception\ValidationException;
use DoubtQueue\Model\SessionStatus;
use DoubtQueue\Repository\SessionRepository;

class SessionService
{
    public function __construct(private SessionRepository $sessions)
    {
    }

    public function create(array $data): array
    {
        $title = $this->requiredText($data, 'title');
        $mentorName = $this->requiredText($data, 'mentor_name');

        return $this->sessions->create($title, $mentorName, SessionStatus::Open->value, gmdate('Y-m-d H:i:s'));
    }

    public function list(?string $status): array
    {
        if ($status !== null && SessionStatus::tryFrom($status) === null) {
            throw new ValidationException('status must be OPEN or CLOSED');
        }

        return $this->sessions->findAll($status);
    }

    public function get(int $id): array
    {
        $session = $this->sessions->find($id);

        if ($session === null) {
            throw new NotFoundException("Session with id $id not found");
        }

        return $session;
    }

    public function close(int $id): array
    {
        $session = $this->get($id);

        if ($session['status'] === SessionStatus::Open->value) {
            $this->sessions->close($id, gmdate('Y-m-d H:i:s'));
        }

        return $this->get($id);
    }

    private function requiredText(array $data, string $field): string
    {
        $value = $data[$field] ?? null;
        $value = is_string($value) ? trim($value) : '';

        if ($value === '') {
            throw new ValidationException("$field is required");
        }

        if (mb_strlen($value) > 255) {
            throw new ValidationException("$field must be 255 characters or fewer");
        }

        return $value;
    }
}
