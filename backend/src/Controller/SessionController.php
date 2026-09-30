<?php

declare(strict_types=1);

namespace DoubtQueue\Controller;

use DoubtQueue\Http\Request;
use DoubtQueue\Http\Response;
use DoubtQueue\Service\SessionService;

class SessionController
{
    public function __construct(private SessionService $sessions)
    {
    }

    public function create(Request $request, array $params): Response
    {
        return new Response(201, $this->sessions->create($request->body()));
    }

    public function list(Request $request, array $params): Response
    {
        $status = $request->query['status'] ?? null;

        return new Response(200, $this->sessions->list(is_string($status) ? $status : null));
    }

    public function get(Request $request, array $params): Response
    {
        return new Response(200, $this->sessions->get($params['id']));
    }

    public function close(Request $request, array $params): Response
    {
        return new Response(200, $this->sessions->close($params['id']));
    }
}
