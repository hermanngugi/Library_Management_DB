-- library_management_system.sql
-- Complete Library Management Database Management System
-- Creates database, tables, constraints, and relationships
-- Target: MySQL (InnoDB)

-- 0. Create the database and select it
CREATE DATABASE IF NOT EXISTS libraryDB
    DEFAULT CHARACTER SET = utf8mb4
    DEFAULT COLLATE = utf8mb4_general_ci;
USE libraryDB;

-- 1. Publishers (1) - a book is published by one publisher
CREATE TABLE publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    website VARCHAR(255),
    contact_email VARCHAR(150),
    phone VARCHAR(40),
    UNIQUE (name)
) ENGINE=InnoDB;

-- 2. Categories / Genres (1) - a book may belong to one primary category
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    UNIQUE (name)
) ENGINE=InnoDB;

-- 3. Authors (many authors can write many books -> M:N via book_authors)
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    bio TEXT,
    birth_date DATE,
    UNIQUE (first_name, last_name)
) ENGINE=InnoDB;

-- 4. Books (book metadata, ISBN unique)
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255),
    publisher_id INT,                     -- FK to publishers
    category_id INT,                      -- FK to categories
    pub_year YEAR,
    pages INT,
    language VARCHAR(50) DEFAULT 'English',
    summary TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE (isbn),
    INDEX idx_title (title),
    FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- 5. Junction table: book_authors (M:N)
CREATE TABLE book_authors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    author_order TINYINT DEFAULT 1, -- ordering of authors on the book
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. Book copies: handling multiple copies/physical items of a book
CREATE TABLE book_copies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    accession_no VARCHAR(50) NOT NULL, -- library accession / inventory number
    acquisition_date DATE,
    purchase_price DECIMAL(10,2),
    location VARCHAR(100),              -- shelf/branch/etc
    status ENUM('available','on_loan','reserved','lost','maintenance') DEFAULT 'available',
    condition VARCHAR(100),             -- e.g., Good, Fair, Damaged
    UNIQUE (accession_no),
    INDEX idx_book_status (book_id, status),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 7. Members (library patrons)
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    membership_no VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    phone VARCHAR(40),
    address VARCHAR(255),
    join_date DATE DEFAULT (CURRENT_DATE),
    status ENUM('active','suspended','cancelled') DEFAULT 'active',
    UNIQUE (membership_no),
    UNIQUE (email)
) ENGINE=InnoDB;

-- 8. Staff
CREATE TABLE staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_no VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    role VARCHAR(100),      -- e.g., Librarian, Assistant, Admin
    hire_date DATE,
    active BOOLEAN DEFAULT TRUE,
    UNIQUE(staff_no),
    UNIQUE(email)
) ENGINE=InnoDB;

-- 9. Loans (borrowing records) - One copy can have many loans over time; a loan references a copy and a member
CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    copy_id INT NOT NULL,
    member_id INT NOT NULL,
    staff_issued_id INT,          -- staff who issued the loan
    loan_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date DATE NOT NULL,
    return_date DATE,
    status ENUM('borrowed','returned','overdue','lost') DEFAULT 'borrowed',
    fine_amount DECIMAL(8,2) DEFAULT 0.00,
    INDEX idx_member_status (member_id, status),
    FOREIGN KEY (copy_id) REFERENCES book_copies(copy_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (staff_issued_id) REFERENCES staff(staff_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- 10. Reservations (members can reserve books / copies)
CREATE TABLE reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    book_id INT NOT NULL,      -- reservation is usually at book level
    copy_id INT,               -- optional: reservation for a particular copy
    reserved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME,
    status ENUM('active','fulfilled','cancelled','expired') DEFAULT 'active',
    FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (copy_id) REFERENCES book_copies(copy_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_member_book (member_id, book_id)
) ENGINE=InnoDB;

-- 11. Fines / Payments (tracking fines or payments made by members)
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    loan_id INT,            -- related loan (if fine payment)
    amount DECIMAL(8,2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    method ENUM('cash','card','online','other') DEFAULT 'cash',
    note VARCHAR(255),
    FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- 12. Audit / Activity Log (optional helpful table)
CREATE TABLE activity_log (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    actor_type ENUM('member','staff','system') NOT NULL,
    actor_id INT,             -- either member_id or staff_id depending on actor_type
    action VARCHAR(100) NOT NULL,
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_actor (actor_type, actor_id)
) ENGINE=InnoDB;

-- 13. Example of Many-to-Many for Tags (books can have many tags, tags can belong to many books)
CREATE TABLE tags (
    tag_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE book_tags (
    book_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (book_id, tag_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(tag_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 14. Useful indexes (additional)
CREATE INDEX idx_books_isbn_title ON books (isbn, title);
CREATE INDEX idx_copies_book_location ON book_copies (book_id, location);
CREATE INDEX idx_loans_due_date ON loans (due_date);

-- 15. Sample Views (optional) - current loans per member
DROP VIEW IF EXISTS vw_current_loans;
CREATE VIEW vw_current_loans AS
SELECT l.loan_id, l.copy_id, b.book_id, b.title, m.member_id, m.first_name, m.last_name,
       l.loan_date, l.due_date, l.return_date, l.status
FROM loans l
JOIN members m ON l.member_id = m.member_id
JOIN book_copies bc ON l.copy_id = bc.copy_id
JOIN books b ON bc.book_id = b.book_id
WHERE l.status <> 'returned';

-- 16. Enforce foreign key checks (ensure InnoDB)
SET FOREIGN_KEY_CHECKS = 1;

-- End of libraryDB schema
