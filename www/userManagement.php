<?php
	session_start();
	class userManagement {
	
		//Choose a unique salt. The longer and more complex it is, the better.
		//Since the database is being stored in an unencrypted file, we need
		//strong protection on the passwords.
		
		private $salt = "@#6$%^&*Tom$%^&Tom(&^A%^&Fx^&**%^&SALT-8,/7%^&*";
		private $dbfile = "tomtomfx.db";
		private $db = -1;
		
		public function dbinit() {
			if ($this->db == -1) 
				$this->db = new SQLite3($this->dbfile);
		}
		
		public function dbclose() {
			if ($this->db != -1) {
				$this->db->close();
				$db = -1;
			}	
		}
			
		public function createTables() {
			$query = "CREATE TABLE IF NOT EXISTS users
					 (id INTEGER PRIMARY KEY  AUTOINCREMENT, 
					  username VARCHAR(255) NOT NULL, 
					  password VARCHAR(32) NOT NULL,
					  lastLogin DATETIME DEFAULT CURRENT_TIME,
					  isAdmin BOOL DEFAULT false);";
			$this->db->exec($query) or die ("Table already exists");
		}
		
		public function login($user, $password) {
			$user = $this->db->escapeString($user);
			$password = md5($this->salt.$password);
			
			$q = "SELECT * FROM users WHERE username = '$user' AND password = '$password' LIMIT 1";
			$queryRes = $this->db->query($q);
			$userInfo = $queryRes->fetchArray();
			if (count($userInfo) > 1) {
				$_SESSION['id'] = $userInfo['id'];
				$_SESSION['username'] = $userInfo['username'];
				$_SESSION['isAdmin'] = $userInfo['isAdmin'];
				$time = time();
				$id = $userInfo['id'];
				$this->db->exec("UPDATE users SET lastlogin = '$time' WHERE id = '$id'");
				return true;
			}
			return false;
		}
		
		//Returns false if username is taken
		public function newUser($username, $password, $isAdmin) {
			$user = $this->db->escapeString($username);
			$pass = md5($this->salt.$password);
			$time = time();
			$checkuser = $this->db->query("SELECT id FROM users WHERE username = '$user'");
			$userlist = $checkuser->fetchArray();
			if (count($userlist) > 1)
			{
				return false;
			}
			$q = "INSERT INTO users VALUES (NULL, '$user', '$pass', '$time', '$isAdmin')";
			return $this->db->query($q) or die("Insert data error...\n");
		}
		
		public function updatePassword($username, $cpass, $newpass) {
			if (!$this->login($username, $cpass)) return false;
			
			// escaping session data is probably unnecessary, but better safe than sorry
			$id = $this->db->escapeString($_SESSION['id']); 
			$q = "UPDATE users SET password = '$newpass' WHERE id = '$id' AND password = '$cpass'";
			return $this->db->query($q);
		}
		
		public function isloggedin() {
			return isset($_SESSION['id']);
		}

		public function logout() {
			unset($_SESSION['id']);
			session_destroy();
		}

		public function uname() {
			if ($this->isloggedin()) 
				return $_SESSION['username'];
			else 
				return "NO LOGIN.";
		}			
	}
	
	$users = new userManagement();
	$users->dbinit();
	
?>