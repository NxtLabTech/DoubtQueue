<?php

declare(strict_types=1);

namespace DoubtQueue\Tests;

use DoubtQueue\DatabaseSetup;
use PDO;
use PDOStatement;
use PHPUnit\Framework\TestCase;

class RecordingPdo extends PDO
{
    /** @var list<string> */
    public array $statements = [];

    public function exec(string $statement): int|false
    {
        $this->statements[] = $statement;
        return parent::exec($statement);
    }

    public function query(string $query, ?int $fetchMode = null, mixed ...$fetchModeArgs): PDOStatement|false
    {
        $this->statements[] = $query;
        if ($fetchMode === null) {
            return parent::query($query);
        }
        return parent::query($query, $fetchMode, ...$fetchModeArgs);
    }

    public function prepare(string $query, array $options = []): PDOStatement|false
    {
        $this->statements[] = $query;
        return parent::prepare($query, $options);
    }

    public function resetLog(): void
    {
        $this->statements = [];
    }
}

class DatabaseSetupTest extends TestCase
{
    private RecordingPdo $pdo;

    protected function setUp(): void
    {
        $this->pdo = new RecordingPdo('sqlite::memory:');
        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        $this->pdo->exec('PRAGMA foreign_keys = ON');
        $this->pdo->resetLog();
    }

    public function testFirstCallCreatesTablesAndSampleData(): void
    {
        $setup = new DatabaseSetup($this->pdo);

        $this->assertFalse($setup->isInitialized());

        $setup->run();

        $this->assertTrue($setup->isInitialized());

        $createStatements = array_filter(
            $this->pdo->statements,
            fn(string $sql) => stripos($sql, 'CREATE') !== false
        );
        $this->assertNotEmpty($createStatements);

        $sessionCount = (int) $this->pdo->query('SELECT COUNT(*) FROM sessions')->fetchColumn();
        $this->assertGreaterThan(0, $sessionCount);

        $doubtCount = (int) $this->pdo->query('SELECT COUNT(*) FROM doubts')->fetchColumn();
        $this->assertGreaterThan(0, $doubtCount);
    }

    public function testSecondCallRunsNoCreateStatementsAndNoSampleDataQuery(): void
    {
        $setup = new DatabaseSetup($this->pdo);

        // First run initializes DB and populates sample data
        $setup->run();
        $this->assertTrue($setup->isInitialized());

        $initialSessions = (int) $this->pdo->query('SELECT COUNT(*) FROM sessions')->fetchColumn();
        $initialDoubts = (int) $this->pdo->query('SELECT COUNT(*) FROM doubts')->fetchColumn();

        // Clear query log before second run
        $this->pdo->resetLog();

        // Second run should detect DB is already initialized and do nothing
        $setup->run();

        $createStatements = array_filter(
            $this->pdo->statements,
            fn(string $sql) => stripos($sql, 'CREATE') !== false
        );
        $this->assertEmpty($createStatements, 'Expected no CREATE statements on second run');

        $countQueries = array_filter(
            $this->pdo->statements,
            fn(string $sql) => stripos($sql, 'SELECT COUNT(*) FROM sessions') !== false
        );
        $this->assertEmpty($countQueries, 'Expected no sample-data count query on second run');

        // Existing data should remain unchanged
        $this->assertSame($initialSessions, (int) $this->pdo->query('SELECT COUNT(*) FROM sessions')->fetchColumn());
        $this->assertSame($initialDoubts, (int) $this->pdo->query('SELECT COUNT(*) FROM doubts')->fetchColumn());
    }

    public function testExistingDataIsNotChangedByRepeatedRequests(): void
    {
        $setup = new DatabaseSetup($this->pdo);
        $setup->run();

        // Add custom record
        $this->pdo->prepare(
            'INSERT INTO sessions (title, mentor_name, status, created_at) VALUES (?, ?, ?, ?)'
        )->execute(['Custom Session', 'Mentor Alex', 'OPEN', '2026-01-01 12:00:00']);
        $customId = (int) $this->pdo->lastInsertId();

        $sessionsCountBefore = (int) $this->pdo->query('SELECT COUNT(*) FROM sessions')->fetchColumn();

        // Repeated run
        $setup->run();

        $sessionsCountAfter = (int) $this->pdo->query('SELECT COUNT(*) FROM sessions')->fetchColumn();
        $this->assertSame($sessionsCountBefore, $sessionsCountAfter);

        $stmt = $this->pdo->prepare('SELECT title FROM sessions WHERE id = ?');
        $stmt->execute([$customId]);
        $this->assertSame('Custom Session', $stmt->fetchColumn());
    }
}
