<?php

declare(strict_types=1);

namespace DoubtQueue\Repository;

use PDO;

class SessionRepository
{
    private const SELECT = "SELECT s.*,
            (SELECT COUNT(*) FROM doubts d WHERE d.session_id = s.id AND d.status = 'WAITING') AS waiting_count
        FROM sessions s";

    public function __construct(private PDO $pdo)
    {
    }

    public function create(string $title, string $mentorName, string $status, string $createdAt): array
    {
        $this->pdo->prepare(
            'INSERT INTO sessions (title, mentor_name, status, created_at) VALUES (?, ?, ?, ?)'
        )->execute([$title, $mentorName, $status, $createdAt]);

        return $this->find((int) $this->pdo->lastInsertId());
    }

    public function find(int $id): ?array
    {
        $stmt = $this->pdo->prepare(self::SELECT . ' WHERE s.id = ?');
        $stmt->execute([$id]);
        $row = $stmt->fetch();

        return $row === false ? null : $this->format($row);
    }

    public function findAll(?string $status): array
    {
        if ($status === null) {
            $stmt = $this->pdo->query(self::SELECT . ' ORDER BY s.created_at DESC, s.id DESC');
        } else {
            $stmt = $this->pdo->prepare(self::SELECT . ' WHERE s.status = ? ORDER BY s.created_at DESC, s.id DESC');
            $stmt->execute([$status]);
        }

        return array_map([$this, 'format'], $stmt->fetchAll());
    }

    public function close(int $id, string $closedAt): void
    {
        $this->pdo->prepare('UPDATE sessions SET status = ?, closed_at = ? WHERE id = ?')
            ->execute(['CLOSED', $closedAt, $id]);
    }

    private function format(array $row): array
    {
        $row['id'] = (int) $row['id'];
        $row['waiting_count'] = (int) $row['waiting_count'];

        return $row;
    }
}
