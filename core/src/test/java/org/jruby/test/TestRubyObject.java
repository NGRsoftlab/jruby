/*
 ***** BEGIN LICENSE BLOCK *****
 * Version: EPL 2.0/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Eclipse Public
 * License Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.eclipse.org/legal/epl-v20.html
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * Copyright (C) 2001-2004 Jan Arne Petersen <jpetersen@uni-bonn.de>
 * Copyright (C) 2002-2004 Anders Bengtsson <ndrsbngtssn@yahoo.se>
 * Copyright (C) 2004 Thomas E Enebo <enebo@acm.org>
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either of the GNU General Public License Version 2 or later (the "GPL"),
 * or the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the EPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the EPL, the GPL or the LGPL.
 ***** END LICENSE BLOCK *****/

package org.jruby.test;

import junit.framework.TestCase;

import org.jruby.Ruby;
import org.jruby.RubyObject;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import static org.jruby.api.Access.objectClass;

public class TestRubyObject extends TestCase {
    private ThreadContext context;
    private IRubyObject rubyObject;

    public TestRubyObject(String name) {
        super(name);
    }

    public void setUp() {
        context = Ruby.newInstance().getCurrentContext();
        rubyObject = new RubyObject(context.runtime, objectClass(context));
    }

    public void testNil() {
        assertFalse(rubyObject.isNil());
    }

    public void testTrue() {
        assertTrue(rubyObject.isTrue());
    }

    public void testEquals() {
        assertEquals(rubyObject, rubyObject);
    }

    public void testClone() {
        assertSame(rubyObject.rbClone().getType(), rubyObject.getType());
    }

    public void testDup() {
        assertSame(rubyObject.dup().getType(), rubyObject.getType());
    }

    public void testType() {
        assertEquals("Object", rubyObject.getType().name(context).toString());
    }

    public void testFreeze() {
        assertFalse(rubyObject.isFrozen());
        rubyObject.setFrozen(true);
        assertTrue(rubyObject.isFrozen());
    }

    public void test_to_s() {
        assertTrue(rubyObject.toString().startsWith("#<Object:0x"));
    }

    public void test_kind_of() {
        assertTrue(objectClass(context).isInstance(rubyObject));
    }
}
