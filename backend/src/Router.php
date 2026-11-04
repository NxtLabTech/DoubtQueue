<?php

declare(strict_types=1);

namespace DoubtQueue;

use DoubtQueue\Exception\MethodNotAllowedException;
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
        $allowedMethods = [];

        foreach ($this->routes as [$method, $regex, $handler]) {
            if (!preg_match($regex, $request->path, $matches)) {
                continue;
            }

            if ($method === $request->method) {
                $params = array_map('intval', array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY));

                return $handler($request, $params);
            }

            $allowedMethods[] = $method;
        }

        if ($allowedMethods !== []) {
            $allowedMethods = array_values(array_unique($allowedMethods));

            throw new MethodNotAllowedException(
                $allowedMethods,
                sprintf(
                    'Method %s is not allowed for this route. Allowed: %s',
                    $request->method,
                    implode(', ', $allowedMethods)
                )
            );
        }

        throw new NotFoundException('Route not found');
    }
}
