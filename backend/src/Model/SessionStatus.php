<?php

declare(strict_types=1);

namespace DoubtQueue\Model;

enum SessionStatus: string
{
    case Open = 'OPEN';
    case Closed = 'CLOSED';
}
