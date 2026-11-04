<?php

declare(strict_types=1);

namespace DoubtQueue\Tests;

use DoubtQueue\Exception\MethodNotAllowedException;
use DoubtQueue\Exception\NotFoundException;
use DoubtQueue\Http\Request;
use DoubtQueue\Http\Response;
use DoubtQueue\Router;
use PHPUnit\Framework\TestCase;

class RouterTest extends TestCase
{
    private Router $router;

    protected function setUp(): void
    {
        $this->router = new Router();
        $this->router->add('POST', '/api/sessions', fn () => new Response(201, ['action' => 'create']));
        $this->router->add('GET', '/api/sessions', fn () => new Response(200, ['action' => 'list']));
        $this->router->add('GET', '/api/sessions/{id}', fn (Request $r, array $p) => new Response(200, $p));
        $this->router->add('PATCH', '/api/sessions/{id}/close', fn () => new Response(200, ['action' => 'close']));
    }

    public function testMatchingRouteIsDispatchedWithParams(): void
    {
        $response = $this->router->dispatch(new Request('GET', '/api/sessions/7'));

        $this->assertSame(200, $response->status);
        $this->assertSame(['id' => 7], $response->body);
    }

    public function testSamePathIsDispatchedByMethod(): void
    {
        $this->assertSame('create', $this->router->dispatch(new Request('POST', '/api/sessions'))->body['action']);
        $this->assertSame('list', $this->router->dispatch(new Request('GET', '/api/sessions'))->body['action']);
    }

    public function testKnownPathWithWrongMethodThrowsMethodNotAllowed(): void
    {
        try {
            $this->router->dispatch(new Request('DELETE', '/api/sessions/1'));
            $this->fail('Expected MethodNotAllowedException');
        } catch (MethodNotAllowedException $e) {
            $this->assertSame(['GET'], $e->allowedMethods);
            $this->assertStringContainsString('DELETE', $e->getMessage());
        }
    }

    public function testAllowedMethodsListsEveryMethodForThePath(): void
    {
        try {
            $this->router->dispatch(new Request('PUT', '/api/sessions'));
            $this->fail('Expected MethodNotAllowedException');
        } catch (MethodNotAllowedException $e) {
            $this->assertSame(['POST', 'GET'], $e->allowedMethods);
        }
    }

    public function testUnknownPathThrowsNotFound(): void
    {
        $this->expectException(NotFoundException::class);
        $this->expectExceptionMessage('Route not found');

        $this->router->dispatch(new Request('GET', '/api/nothing'));
    }

    public function testUnknownPathWithAnyMethodThrowsNotFound(): void
    {
        $this->expectException(NotFoundException::class);

        $this->router->dispatch(new Request('DELETE', '/api/nothing'));
    }

    public function testNonNumericIdThrowsNotFound(): void
    {
        $this->expectException(NotFoundException::class);

        $this->router->dispatch(new Request('POST', '/api/sessions/abc'));
    }
}
