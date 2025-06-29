# Collaborative Project Management Smart Contract

A decentralized platform built on the Stacks blockchain for managing collaborative projects, task assignments, milestone tracking, and automated payments between team members with integrated performance metrics.

## Features

- **Decentralized Project Management**: Create and manage projects entirely on-chain
- **Team Collaboration**: Add team members and assign tasks with role-based permissions
- **Automated Payments**: Automatic STX transfers upon task completion
- **Performance Tracking**: Built-in analytics for team member performance and earnings
- **Task Management**: Comprehensive task lifecycle management with status tracking
- **Access Control**: Secure permissions system ensuring only authorized users can perform actions

## Contract Overview

This smart contract enables:
- Project owners to create projects with budgets and team management
- Task creation and assignment to team members
- Automated payment processing upon task completion
- Performance metrics tracking for team members
- Read-only functions for querying project and task data

## Core Data Structures

### Projects
- Project ID, name, and description
- Owner address and team member list
- Budget allocation and current status
- Creation timestamp

### Tasks
- Task ID, title, and detailed description
- Assigned team member and compensation amount
- Deadline and current status
- Parent project association

### Performance Metrics
- Total completed tasks per member
- Cumulative earnings tracking
- Average performance ratings
- Total ratings received

## Public Functions

### Project Management

#### `create-new-collaborative-project`
```clarity
(create-new-collaborative-project (project-name (string-ascii 50)) 
                                 (detailed-description (string-ascii 500)) 
                                 (initial-budget uint))
```
Creates a new project with the specified parameters.

**Parameters:**
- `project-name`: Name of the project (max 50 characters)
- `detailed-description`: Project description (max 500 characters)
- `initial-budget`: Budget allocated for the project

**Returns:** Project ID if successful

#### `add-team-member-to-project`
```clarity
(add-team-member-to-project (target-project-id uint) 
                           (new-member-wallet-address principal))
```
Adds a new team member to an existing project (owner only).

### Task Management

#### `create-and-assign-task`
```clarity
(create-and-assign-task (target-project-id uint)
                       (task-name (string-ascii 50))
                       (comprehensive-task-description (string-ascii 500))
                       (designated-assignee-address principal)
                       (task-completion-deadline uint)
                       (task-payment-amount uint))
```
Creates and assigns a new task to a team member (owner only).

#### `modify-task-status`
```clarity
(modify-task-status (target-project-id uint) 
                   (target-task-id uint) 
                   (updated-status-value (string-ascii 20)))
```
Updates the status of an existing task (owner or assignee only).

#### `finalize-task-completion`
```clarity
(finalize-task-completion (target-project-id uint) (target-task-id uint))
```
Completes a task and automatically processes payment from project owner to assignee.

### Performance Management

#### `submit-team-member-rating`
```clarity
(submit-team-member-rating (target-member-address principal) 
                          (performance-rating-score uint))
```
Submit a performance rating (1-5) for a team member.

## Read-Only Functions

### `fetch-project-information`
Retrieves complete information about a specific project.

### `fetch-task-information`
Gets detailed information about a specific task within a project.

### `fetch-member-performance-analytics`
Returns performance metrics for a specific team member.

### `check-project-access-permissions`
Verifies if an address has access to a specific project.

## Access Control

The contract implements a comprehensive permission system:

- **Project Owners**: Can create tasks, add team members, and modify project settings
- **Team Members**: Can update their assigned task statuses and complete tasks
- **Task Assignees**: Can complete their assigned tasks to trigger automatic payments

## Payment System

- Automatic STX transfers upon task completion
- Payments are transferred from project owner to task assignee
- All transactions are recorded on-chain for transparency
- Performance metrics are automatically updated after each completion

## Error Handling

The contract includes comprehensive error handling with specific error codes:

- `u100`: Unauthorized access
- `u101`: Project does not exist
- `u102`: Task does not exist
- `u103`: Invalid status transition
- `u104`: Insufficient project balance
- `u105`: Project ID already exists
- `u106`: Task ID already exists
- `u107`: Invalid parameter provided
- `u108`: Team member already exists
- `u109`: Maximum team size exceeded

## Performance Metrics

Each team member's performance is tracked including:
- Total number of completed tasks
- Cumulative earnings from all projects
- Average performance rating
- Total number of ratings received

## Usage Example

```clarity
;; Create a new project
(contract-call? .collaborative-project-management 
  create-new-collaborative-project 
  "My Awesome Project" 
  "A revolutionary blockchain application" 
  u1000000)

;; Add a team member
(contract-call? .collaborative-project-management 
  add-team-member-to-project 
  u0 
  'SP1EXAMPLE...)

;; Create a task
(contract-call? .collaborative-project-management 
  create-and-assign-task 
  u0 
  "Frontend Development" 
  "Build the user interface for the application" 
  'SP1EXAMPLE... 
  u2000 
  u100000)
```

## Important Considerations

- Ensure sufficient STX balance for project owners before task completion
- Task deadlines are validated against current block height
- Maximum team size is limited to 20 members per project
- All string parameters have specific length limitations
- Performance ratings must be between 1-5