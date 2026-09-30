<?php

declare(strict_types=1);

namespace DoubtQueue\Tests\Service;

use DoubtQueue\Database;
use DoubtQueue\DatabaseSetup;
use DoubtQueue\Exception\ValidationException;
use DoubtQueue\Repository\SessionRepository;
use DoubtQueue\Service\SessionService;
use PHPUnit\Framework\TestCase;

class SessionServiceTest extends TestCase
{
    private SessionService $sessions;

    protected function setUp(): void
    {
        $pdo = Database::memory();
        (new DatabaseSetup($pdo))->createTables();

        $this->sessions = new SessionService(new SessionRepository($pdo));
    }

    public function testCreatingSessionWorks(): void
    {
        $session = $this->sessions->create(['title' => 'PHP Basics', 'mentor_name' => 'Priya']);

        $this->assertSame('PHP Basics', $session['title']);
        $this->assertSame('Priya', $session['mentor_name']);
        $this->assertSame('OPEN', $session['status']);
        $this->assertSame(0, $session['waiting_count']);
        $this->assertNull($session['closed_at']);
    }

    public function testCreatingSessionWithoutTitleThrows(): void
    {
        $this->expectException(ValidationException::class);

        $this->sessions->create(['mentor_name' => 'Priya']);
    }

    public function testClosingSessionSetsClosedAt(): void
    {
        $session = $this->sessions->create(['title' => 'PHP Basics', 'mentor_name' => 'Priya']);

        $closed = $this->sessions->close($session['id']);

        $this->assertSame('CLOSED', $closed['status']);
        $this->assertNotNull($closed['closed_at']);
    }

    public function testListFiltersByStatus(): void
    {
        $open = $this->sessions->create(['title' => 'Open one', 'mentor_name' => 'Priya']);
        $closed = $this->sessions->create(['title' => 'Closed one', 'mentor_name' => 'Arjun']);
        $this->sessions->close($closed['id']);

        $ids = array_column($this->sessions->list('OPEN'), 'id');

        $this->assertSame([$open['id']], $ids);
    }
}
