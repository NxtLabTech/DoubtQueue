<?php

declare(strict_types=1);

namespace DoubtQueue\Exception;

use RuntimeException;

class MethodNotAllowedException extends RuntimeException
{
    /**
     * @param string[] $allowedMethods
     */
    public function __construct(public readonly array $allowedMethods, string $message = 'Method not allowed')
    {
        parent::__construct($message);
    }
}
