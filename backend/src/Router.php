<?php

declare(strict_types=1);

namespace DoubtQueue;

use DoubtQueue\Exception\NotFoundException;
use DoubtQueue\Http\Request;
use DoubtQueue\Http\Response;

class Router
{
    private array $routes = [];

    public function add(string $method, string $pattern, callable $handler): void
    {
        $regex = preg_replace('#\{(\w+)\}#', '(?P<$1>\d+)', $pattern);
        $this->routes[] = [$method, '#^' . $regex . '$#', $handler];
    }

    public function dispatch(Request $request): Response
    {
        foreach ($this->routes as [$method, $regex, $handler]) {
            if ($method === $request->method && preg_match($regex, $request->path, $matches)) {
                $params = array_map('intval', array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY));

                return $handler($request, $params);
            }
        }

        throw new NotFoundException('Route not found');
    }
}
