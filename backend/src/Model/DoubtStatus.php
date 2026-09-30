<?php

declare(strict_types=1);

namespace DoubtQueue\Model;

enum DoubtStatus: string
{
    case Waiting = 'WAITING';
    case InProgress = 'IN_PROGRESS';
    case Solved = 'SOLVED';
    case Skipped = 'SKIPPED';
}
