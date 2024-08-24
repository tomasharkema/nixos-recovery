package startup

import (
	"bufio"
	"io"
	"regexp"
)

var lineRegex = regexp.MustCompile("(Boot([0-9A-F]{4}))(\\*)?\\s(.*)[\\t](.*)$")

type Result struct {
	BootEntry string
	BootNum   string
	Star      string
	Name      string
	Device    string
}

type Scanner struct {
	r        *bufio.Scanner
	token    Result
	match    []string
	currText string
}

func NewScanner(r io.Reader) *Scanner {

	return &Scanner{
		r: bufio.NewScanner(r),
	}
}

func (s *Scanner) Scan() bool {

	lineScan := s.r.Scan()
	if !lineScan {
		return false
	}

	s.currText = s.r.Text()

	s.match = lineRegex.FindStringSubmatch(s.currText)

	if len(s.match) > 2 {

		s.token = Result{
			s.match[1], s.match[2], s.match[3], s.match[4], s.match[5],
		}
		return true
	}

	return s.Scan()
}

func (s *Scanner) Text() Result {
	return s.token
}
