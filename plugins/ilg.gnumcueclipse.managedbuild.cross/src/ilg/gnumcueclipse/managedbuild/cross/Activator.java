/*******************************************************************************
 * Copyright (c) 2014 Liviu Ionescu.
 *
 * This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License 2.0
 * which accompanies this distribution, and is available at
 * https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 * 
 * Contributors:
 *     Liviu Ionescu - initial implementation.
 *******************************************************************************/

package ilg.gnumcueclipse.managedbuild.cross;

import org.osgi.framework.BundleContext;

import ilg.gnumcueclipse.core.AbstractUIActivator;
import ilg.gnumcueclipse.managedbuild.cross.preferences.PersistentPreferences;

/**
 * The activator class controls the plug-in life cycle
 */
public class Activator extends AbstractUIActivator {

	// ------------------------------------------------------------------------

	// The plug-in ID
	public static final String PLUGIN_ID = "ilg.gnumcueclipse.managedbuild.cross"; //$NON-NLS-1$

	@Override
	public String getBundleId() {
		return PLUGIN_ID;
	}

	// ------------------------------------------------------------------------

	// The shared instance
	private static Activator fgInstance;

	public static Activator getInstance() {
		return fgInstance;
	}

	protected PersistentPreferences fPersistentPreferences;

	public Activator() {

		super();
		fgInstance = this;

		fPersistentPreferences = new PersistentPreferences(PLUGIN_ID);
	}

	// ------------------------------------------------------------------------

	public void start(BundleContext context) throws Exception {
		super.start(context);
	}

	public void stop(BundleContext context) throws Exception {
		super.stop(context);
	}

	public PersistentPreferences getPersistentPreferences() {
		return fPersistentPreferences;
	}

	// ------------------------------------------------------------------------
}
